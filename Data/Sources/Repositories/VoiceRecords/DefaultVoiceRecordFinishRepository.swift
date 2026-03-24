import Core
import Domain

public struct DefaultVoiceRecordFinishRepository: VoiceRecordFinishRepository {
    private let service: any AudioRecorderService

    public init(service: any AudioRecorderService) {
        self.service = service
    }

    public func finishRecording() async throws(VoiceRecordFinishRepositoryError) -> VoiceRecord {
        if Task.isCancelled { throw .cancelled }

        do {
            let recordedAudio = try await service.finishRecording()
            return VoiceRecord(
                createdAt: recordedAudio.createdAt,
                audioFilePath: recordedAudio.audioFilePath,
                duration: recordedAudio.duration
            )
        } catch {
            AppLogger.error(error)
            throw VoiceRecordFinishRepositoryError(error)
        }
    }
}
