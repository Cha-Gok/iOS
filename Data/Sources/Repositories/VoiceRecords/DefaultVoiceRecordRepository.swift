import Core
import Domain

public struct DefaultVoiceRecordRepository: VoiceRecordRepository {
    private let audioService: any AudioRecorderService

    public init(audioService: any AudioRecorderService) {
        self.audioService = audioService
    }

    public func checkMicrophonePermission() async throws(VoiceRecordRepositoryError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }
        return await audioService.checkPermission()
    }

    public func requestMicrophonePermission() async throws(VoiceRecordRepositoryError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }
        return await audioService.requestPermission()
    }

    public func startRecording() async throws(VoiceRecordRepositoryError) -> AsyncStream<Waveform> {
        if Task.isCancelled { throw .cancelled }
        do {
            return try await audioService.startRecording()
        } catch {
            AppLogger.error(error)
            throw VoiceRecordRepositoryError(error)
        }
    }

    public func pauseRecording() async throws(VoiceRecordRepositoryError) {
        if Task.isCancelled { throw .cancelled }
        do {
            try await audioService.pauseRecording()
        } catch {
            AppLogger.error(error)
            throw VoiceRecordRepositoryError(error)
        }
    }

    public func resumeRecording() async throws(VoiceRecordRepositoryError) {
        if Task.isCancelled { throw .cancelled }
        do {
            try await audioService.resumeRecording()
        } catch {
            AppLogger.error(error)
            throw VoiceRecordRepositoryError(error)
        }
    }

    public func finishRecording() async throws(VoiceRecordRepositoryError) -> VoiceRecord {
        if Task.isCancelled { throw .cancelled }
        do {
            let recorded = try await audioService.finishRecording()
            return VoiceRecord(
                createdAt: recorded.createdAt,
                audioFilePath: recorded.audioFilePath,
                duration: recorded.duration
            )
        } catch {
            AppLogger.error(error)
            throw VoiceRecordRepositoryError(error)
        }
    }
}
