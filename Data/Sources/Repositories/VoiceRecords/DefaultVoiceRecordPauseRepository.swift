import Core
import Domain

public struct DefaultVoiceRecordPauseRepository: VoiceRecordPauseRepository {
    private let service: any AudioRecorderService

    public init(service: any AudioRecorderService) {
        self.service = service
    }

    public func pauseRecording() async throws(VoiceRecordPauseRepositoryError) {
        if Task.isCancelled { throw .cancelled }

        do {
            try await service.pauseRecording()
        } catch {
            AppLogger.error(error)
            throw VoiceRecordPauseRepositoryError(error)
        }
    }
}
