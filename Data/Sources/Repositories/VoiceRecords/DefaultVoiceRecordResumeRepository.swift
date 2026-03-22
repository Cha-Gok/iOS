import Core
import Domain

public struct DefaultVoiceRecordResumeRepository: VoiceRecordResumeRepository {
    private let service: any AudioRecorderService

    public init(service: any AudioRecorderService) {
        self.service = service
    }

    public func resumeRecording() async throws(VoiceRecordResumeRepositoryError) {
        if Task.isCancelled { throw .cancelled }

        do {
            try await service.resumeRecording()
        } catch {
            AppLogger.error(error)
            throw VoiceRecordResumeRepositoryError(error)
        }
    }
}
