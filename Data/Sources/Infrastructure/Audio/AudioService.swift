import AVFoundation
import Core
import Domain

/// AVAudioSession 및 AVAudioEngine 기반 오디오 서비스
public actor AudioService: MicrophonePermissionService, AudioRecorderService {
    private var engine: AVAudioEngine?
    private var isPaused = false

    public init() {}

    // MARK: - MicrophonePermissionService

    public func checkPermission() async -> PermissionStatus {
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

    public func requestPermission() async -> PermissionStatus {
        let granted = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        return granted ? .authorized : .denied
    }

    // MARK: - AudioRecorderService

    public func startRecording() async throws(AudioRecorderServiceError) -> AsyncStream<Waveform> {
        guard engine == nil else { throw .alreadyRecording }
        try await activateSession()
        let engine = AVAudioEngine()
        self.engine = engine
        isPaused = false

        let (stream, continuation) = AsyncStream.makeStream(of: Waveform.self)
        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)

        inputNode.installTap(
            onBus: 0,
            bufferSize: AVAudioFrameCount(Policy.waveformTapBufferSize),
            format: format
        ) { buffer, _ in
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            let stride = max(1, frameLength / Policy.waveformSamplesPerBuffer)
            var samples: [Float] = []
            var index = 0
            while index < frameLength, samples.count < Policy.waveformSamplesPerBuffer {
                samples.append(abs(channelData[index]))
                index += stride
            }
            continuation.yield(Waveform(amplitudes: samples))
        }

        continuation.onTermination = { [weak self] _ in
            Task { await self?.stopEngine() }
        }

        do {
            try engine.start()
        } catch {
            AppLogger.error(error)
            continuation.finish()
            throw .startFailed
        }

        return stream
    }

    public func pauseRecording() async throws(AudioRecorderServiceError) {
        guard let engine else { throw .notRecording }
        guard isPaused == false else { throw .pauseFailed }

        guard engine.isRunning else { throw .pauseFailed }

        engine.pause()
        isPaused = true
    }

    public func resumeRecording() async throws(AudioRecorderServiceError) {
        guard let engine else { throw .notPaused }
        guard isPaused else { throw .notPaused }

        try await activateSession()

        do {
            try engine.start()
            isPaused = false
        } catch {
            AppLogger.error(error)
            throw .resumeFailed
        }
    }

    // MARK: - Private

    private func activateSession() async throws(AudioRecorderServiceError) {
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

    private func stopEngine() {
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
        isPaused = false
        Task { await deactivateSession() }
    }

    private func deactivateSession() async {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
