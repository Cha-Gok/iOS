import AVFoundation
import Core
import Domain

/// AVAudioSession 및 AVAudioRecorder 기반 오디오 서비스
public actor AudioService: AudioRecorderService {
    /// 파형 업데이트 주기 (나노초 단위, 기본값 0.1초)
    private let waveformUpdateInterval: UInt64 = 100_000_000
    /// 내부 오디오 레코더 인스턴스
    private var recorder: AVAudioRecorder?
    /// 현재 녹음 중인 파일의 저장 경로
    private var recordingFilePath: URL?
    /// 녹음 시작 일시
    private var recordingCreatedAt: Date?
    /// 파형 데이터 스트림을 제어하기 위한 Continuation
    private var waveformContinuation: AsyncStream<Waveform>.Continuation?
    /// 주기적으로 파형을 업데이트하는 비동기 작업
    private var waveformTask: Task<Void, Never>?
    /// 내부 오디오 레코더 델리게이트
    private var recorderDelegate: RecorderDelegate?
    /// 녹음 일시정지 상태 여부
    private var isPaused = false
    /// 녹음 종료 절차가 진행 중인지 여부
    private var isFinishing = false

    public init() {}

    // MARK: - MicrophonePermissionService

    /// 기기의 마이크 접근 권한 상태를 확인합니다.
    public nonisolated func checkPermission() -> PermissionStatus {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            return .authorized
        case .denied:
            return .denied
        case .undetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    /// 사용자에게 마이크 접근 권한을 요청합니다.
    public func requestPermission() async -> PermissionStatus {
        let granted = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        return granted ? .authorized : .denied
    }

    // MARK: - AudioRecorderService

    /// 오디오 녹음을 시작하고 실시간 파형(Waveform) 데이터 스트림을 반환합니다.
    public func startRecording(at filePath: URL) async throws(AudioRecorderServiceError) -> AsyncStream<Waveform> {
        guard recorder == nil else { throw .alreadyRecording }
        guard AVAudioApplication.shared.recordPermission == .granted else {
            throw .startFailed
        }
        try activateSession()

        let recordingCreatedAt = Date.now
        let recorder: AVAudioRecorder
        do {
            recorder = try makeRecorder(filePath: filePath)
        } catch {
            deactivateSession()
            throw error
        }

        let delegate = RecorderDelegate { [weak self] successfully in
            Task {
                await self?.handleRecordingFinished(successfully: successfully)
            }
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
        recordingFilePath = filePath
        self.recordingCreatedAt = recordingCreatedAt
        self.waveformContinuation = waveformContinuation
        waveformTask = Task { [weak self] in
            await self?.streamWaveform()
        }
        isPaused = false
        isFinishing = false

        AppLogger.info("녹음 시작")
        return waveformStream
    }

    /// 현재 진행 중인 녹음을 정상적으로 종료하고 저장된 오디오 결과물을 반환합니다.
    public func finishRecording() async throws(AudioRecorderServiceError) -> RecordedAudio {
        guard let recorder, let recordingFilePath, let recordingCreatedAt else {
            throw .notRecording
        }

        isFinishing = true
        closeWaveformStream()
        recorder.stop()
        await stopWaveformTask()

        let result = buildRecordedAudio(
            filePath: recordingFilePath,
            createdAt: recordingCreatedAt
        )

        clearRecordingSession()
        deactivateSession()
        AppLogger.info("녹음 종료")

        switch result {
        case .success(let recordedAudio):
            return recordedAudio
        case .failure(let error):
            throw error
        }
    }

    /// 진행 중인 녹음을 일시정지합니다.
    public func pauseRecording() async throws(AudioRecorderServiceError) {
        guard let recorder else { throw .notRecording }
        guard isPaused == false else { throw .pauseFailed }
        guard recorder.isRecording else { throw .pauseFailed }

        recorder.pause()
        isPaused = true
        AppLogger.info("녹음 일시정지")
    }

    /// 일시정지된 녹음을 다시 재개합니다.
    public func resumeRecording() async throws(AudioRecorderServiceError) {
        guard let recorder else { throw .notPaused }
        guard isPaused else { throw .notPaused }

        try activateSession()

        guard recorder.record() else {
            throw .resumeFailed
        }

        isPaused = false
        AppLogger.info("녹음 재개")
    }

    /// 진행 중인 녹음을 취소하고 내부 상태를 정리합니다. 임시 파일 삭제는 Repository가 담당합니다.
    public func cancelRecording() async {
        await stopRecordingSession()
    }

    public func currentRecordingURL() async -> URL? {
        recordingFilePath
    }

    /// 오디오 세션을 녹음 모드로 활성화합니다.
    private func activateSession() throws(AudioRecorderServiceError) {
        let avSession = AVAudioSession.sharedInstance()
        do {
            try avSession.setCategory(.record, mode: .default)
            try avSession.setActive(true)
        } catch {
            AppLogger.error(error)
            let nsError = error as NSError
            switch AVAudioSession.ErrorCode(rawValue: nsError.code) {
            case .insufficientPriority:
                throw .sessionActivationFailed
            case .mediaServicesFailed:
                throw .mediaServicesFailed
            default:
                throw .unknown(error)
            }
        }
    }

    /// 지정된 경로에 오디오 파일을 저장하도록 레코더를 생성하고 초기 설정을 수행합니다.
    private func makeRecorder(filePath: URL) throws(AudioRecorderServiceError) -> AVAudioRecorder {
        do {
            let recorder = try AVAudioRecorder(url: filePath, settings: makeRecordingSettings())
            recorder.isMeteringEnabled = true
            recorder.prepareToRecord()
            return recorder
        } catch {
            AppLogger.error(error)
            throw .startFailed
        }
    }

    /// 지정된 주기마다 레코더의 현재 음량 데이터를 측정하여 파형 스트림으로 방출(yield)합니다.
    private func streamWaveform() async {
        while Task.isCancelled == false {
            guard let recorder else { return }
            guard isFinishing == false else { return }

            if isPaused {
                try? await Task.sleep(nanoseconds: waveformUpdateInterval)
                continue
            }

            if recorder.isRecording {
                recorder.updateMeters()
                waveformContinuation?.yield(Self.makeWaveform(from: recorder))
            }

            try? await Task.sleep(nanoseconds: waveformUpdateInterval)
        }
    }

    /// 시스템이나 외부 요인(예: 전화 수신)에 의해 예기치 않게 녹음이 중단되었을 때의 방어 처리를 수행합니다.
    private func handleRecordingFinished(successfully flag: Bool) async {
        guard recorder != nil else { return }
        guard isFinishing == false else { return }
        await stopRecordingSession()
    }

    /// 파형 스트림이 외부 요인에 의해 종료(Termination)되었을 때 관련 작업을 정리합니다.
    /// 녹음 자체는 명시적인 `finishRecording()` 호출 시에만 종료되며, 스트림 해제(예: 화면 이탈)는 녹음 중단 사유가 되지 않습니다.
    private func handleWaveformTermination() async {
        guard isFinishing == false else { return }
        closeWaveformStream()
        await stopWaveformTask()
        AppLogger.info("파형 스트림 종료 (녹음은 계속 유지됨)")
    }

    /// 현재 진행 중이던 녹음 작업을 중단하고 정리를 수행합니다.
    private func stopRecordingSession() async {
        guard let recorder else { return }

        isFinishing = true
        closeWaveformStream()
        recorder.stop()
        await stopWaveformTask()

        clearRecordingSession()
        deactivateSession()
        AppLogger.info("녹음 중단")
    }

    /// 저장된 오디오 파일을 읽어들여 재생 시간 등의 메타데이터가 포함된 객체를 생성합니다.
    private func buildRecordedAudio(
        filePath: URL,
        createdAt: Date
    ) -> Result<RecordedAudio, AudioRecorderServiceError> {
        do {
            let audioFile = try AVAudioFile(forReading: filePath)
            let duration = audioFile.processingFormat.sampleRate > 0
                ? Double(audioFile.length) / audioFile.processingFormat.sampleRate
                : Date.now.timeIntervalSince(createdAt)

            let recordedAudio = RecordedAudio(
                createdAt: createdAt,
                audioFilePath: filePath,
                duration: duration
            )
            return .success(recordedAudio)
        } catch {
            AppLogger.error(error)
            return .failure(.encodingFailed)
        }
    }

    private func closeWaveformStream() {
        waveformContinuation?.finish()
        waveformContinuation = nil
    }

    private func stopWaveformTask() async {
        let waveformTask = waveformTask
        self.waveformTask = nil
        waveformTask?.cancel()
        await waveformTask?.value
    }

    private func clearRecordingSession() {
        recorder?.delegate = nil
        recorder = nil
        recorderDelegate = nil
        recordingFilePath = nil
        recordingCreatedAt = nil
        waveformContinuation = nil
        waveformTask = nil
        isPaused = false
        isFinishing = false
    }

    private func makeRecordingSettings() -> [String: Any] {
        [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 64000
        ]
    }

    private nonisolated static func makeWaveform(from recorder: AVAudioRecorder) -> Waveform {
        let averagePower = recorder.averagePower(forChannel: 0)
        let normalizedPower = max(0, min(1, pow(10, averagePower / 20)))
        let amplitudes = Array(repeating: normalizedPower, count: Policy.waveformSamplesPerBuffer)
        return Waveform(amplitudes: amplitudes)
    }

    private func deactivateSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            AppLogger.error(error)
        }
    }
}

// MARK: - RecorderDelegate

/// 내부 오디오 레코더 이벤트를 처리하기 위한 델리게이트
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
