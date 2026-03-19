import Core
import Domain

public struct DefaultVoiceRecordStartRepository: VoiceRecordStartRepository {
    private let service: any AudioRecorderService

    public init(service: any AudioRecorderService) {
        self.service = service
    }

    public func startRecording() async throws(VoiceRecordStartRepositoryError) -> AsyncStream<Waveform> {
        if Task.isCancelled { throw .cancelled }
        do {
            return try await service.startRecording()
        } catch {
            AppLogger.error(error)
            throw VoiceRecordStartRepositoryError(error)
        }
    }
}
