import AVFoundation
import Core
import Domain
import Foundation

/// 오디오 녹음을 담당하는 리포지토리 기본 구현체.
public actor DefaultVoiceRecordRepository: VoiceRecordRepository {
    private let storageService: any StorageService

    // AudioService에서 가져온 프로퍼티들
    private let waveformUpdateInterval: UInt64 = 100_000_000
    private var recorder: AVAudioRecorder?
    private var recordingFilePath: URL?
    private var recordingCreatedAt: Date?
    private var waveformContinuation: AsyncStream<Waveform>.Continuation?
    private var waveformTask: Task<Void, Never>?
    private var recorderDelegate: RecorderDelegate?
    private var isPaused = false
    private var isFinishing = false

    public init(storageService: any StorageService) {
        self.storageService = storageService
    }

    // MARK: - VoiceRecordRepository (Permission)

    public nonisolated func checkMicrophonePermission() -> PermissionStatus {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: return .authorized
        case .denied: return .denied
        case .undetermined: return .notDetermined
        @unknown default: return .denied
        }
    }

    public func requestMicrophonePermission() async throws(VoiceRecordRepositoryError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }
        let granted = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        return granted ? .authorized : .denied
    }

    // MARK: - VoiceRecordRepository (Recording Control)

    public func startRecording() async throws(VoiceRecordRepositoryError) -> AsyncStream<Waveform> {
        if Task.isCancelled { throw .cancelled }
        guard recorder == nil else { throw .alreadyRecording }

        let fileName = "\(Date.now.yyyyMMddHHmmssString).m4a"
        let tempURL: URL
        do {
            tempURL = try storageService.generateTemporaryURL(fileName: fileName)
        } catch {
            throw .startFailed
        }

        try activateSession()

        let recorder: AVAudioRecorder
        do {
            recorder = try makeRecorder(filePath: tempURL)
        } catch {
            deactivateSession()
            throw .startFailed
        }

        let delegate = RecorderDelegate { [weak self] successfully in
            Task { await self?.handleRecordingFinished(successfully: successfully) }
        }
        recorder.delegate = delegate

        let (waveformStream, waveformContinuation) = AsyncStream.makeStream(
            of: Waveform.self,
            bufferingPolicy: .bufferingNewest(Policy.waveformStreamBufferLimit)
        )
        waveformContinuation.onTermination = { [weak self] _ in
            Task { await self?.handleWaveformTermination() }
        }

        guard recorder.record() else {
            waveformContinuation.finish()
            deactivateSession()
            throw .startFailed
        }

        recorderDelegate = delegate
        self.recorder = recorder
        recordingFilePath = tempURL
        recordingCreatedAt = Date.now
        self.waveformContinuation = waveformContinuation
        waveformTask = Task { [weak self] in await self?.streamWaveform() }
        isPaused = false
        isFinishing = false

        AppLogger.info("녹음 시작: \(tempURL.lastPathComponent)")
        return waveformStream
    }

    public func pauseRecording() async throws(VoiceRecordRepositoryError) {
        guard let recorder, isPaused == false, recorder.isRecording else { throw .pauseFailed }
        recorder.pause()
        isPaused = true
        AppLogger.info("녹음 일시정지")
    }

    public func resumeRecording() async throws(VoiceRecordRepositoryError) {
        guard let recorder, isPaused else { throw .notPaused }
        try activateSession()
        guard recorder.record() else { throw .resumeFailed }
        isPaused = false
        AppLogger.info("녹음 재개")
    }

    public func cancelRecording() async throws(VoiceRecordRepositoryError) {
        let currentURL = recordingFilePath
        await stopRecordingSession()
        if let currentURL {
            try? storageService.delete(fileURL: currentURL)
        }
    }

    public func finishRecording() async throws(VoiceRecordRepositoryError) -> VoiceRecord {
        guard let recorder, let recordingFilePath, let recordingCreatedAt else {
            throw .notRecording
        }

        isFinishing = true
        closeWaveformStream()
        recorder.stop()
        await stopWaveformTask()

        let recorded: RecordedAudio
        do {
            let audioFile = try AVAudioFile(forReading: recordingFilePath)
            let duration = audioFile.processingFormat.sampleRate > 0
                ? Double(audioFile.length) / audioFile.processingFormat.sampleRate
                : Date.now.timeIntervalSince(recordingCreatedAt)

            recorded = RecordedAudio(
                createdAt: recordingCreatedAt,
                audioFilePath: recordingFilePath,
                duration: duration
            )
        } catch {
            AppLogger.error(error)
            await stopRecordingSession()
            throw .encodingFailed
        }

        clearRecordingSession()
        deactivateSession()

        // Storage 이동 로직 (기존 Repository에 있던 것)
        do {
            let normalizedExtension = recorded.audioFilePath.pathExtension.trimmingCharacters(
                in: CharacterSet(charactersIn: ".")
            )
            let fileName = "\(recorded.createdAt.yyyyMMddHHmmssString).\(normalizedExtension)"
            let relativePath = try storageService.moveFile(
                from: recorded.audioFilePath,
                toDirectory: "VoiceRecords",
                fileName: fileName
            )

            return VoiceRecord(
                createdAt: recorded.createdAt,
                audioFilePath: relativePath,
                duration: recorded.duration
            )
        } catch {
            AppLogger.error(error)
            throw .finishFailed
        }
    }

    // MARK: - Private (Session & Recorder Helpers)

    private func activateSession() throws(VoiceRecordRepositoryError) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            throw .startFailed
        }
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func makeRecorder(filePath: URL) throws -> AVAudioRecorder {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 64000
        ]
        let recorder = try AVAudioRecorder(url: filePath, settings: settings)
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()
        return recorder
    }

    private func streamWaveform() async {
        while !Task.isCancelled {
            guard let recorder, !isFinishing else { return }
            if isPaused {
                try? await Task.sleep(nanoseconds: waveformUpdateInterval)
                continue
            }
            if recorder.isRecording {
                recorder.updateMeters()
                let averagePower = recorder.averagePower(forChannel: 0)
                let normalizedPower = max(0, min(1, pow(10, averagePower / 20)))
                let amplitudes = Array(repeating: normalizedPower, count: Policy.waveformSamplesPerBuffer)
                waveformContinuation?.yield(Waveform(amplitudes: amplitudes))
            }
            try? await Task.sleep(nanoseconds: waveformUpdateInterval)
        }
    }

    private func handleRecordingFinished(successfully flag: Bool) async {
        guard recorder != nil, !isFinishing else { return }
        await stopRecordingSession()
    }

    private func handleWaveformTermination() async {
        guard !isFinishing else { return }
        closeWaveformStream()
        await stopWaveformTask()
    }

    private func stopRecordingSession() async {
        isFinishing = true
        closeWaveformStream()
        recorder?.stop()
        await stopWaveformTask()
        clearRecordingSession()
        deactivateSession()
    }

    private func closeWaveformStream() {
        waveformContinuation?.finish()
        waveformContinuation = nil
    }

    private func stopWaveformTask() async {
        let task = waveformTask
        waveformTask = nil
        task?.cancel()
        _ = await task?.result
    }

    private func clearRecordingSession() {
        recorder?.delegate = nil
        recorder = nil
        recorderDelegate = nil
        recordingFilePath = nil
        recordingCreatedAt = nil
        isPaused = false
        isFinishing = false
    }
}

// MARK: - RecorderDelegate (Helper)

private final class RecorderDelegate: NSObject, AVAudioRecorderDelegate, @unchecked Sendable {
    let onDidFinishRecording: @Sendable (Bool) -> Void
    init(onDidFinishRecording: @escaping @Sendable (Bool) -> Void) {
        self.onDidFinishRecording = onDidFinishRecording
        super.init()
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        onDidFinishRecording(flag)
    }
}
