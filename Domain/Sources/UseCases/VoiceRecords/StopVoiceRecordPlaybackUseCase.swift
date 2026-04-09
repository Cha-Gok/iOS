import Core
import Foundation

public protocol StopVoiceRecordPlaybackUseCase: Sendable {
    func execute() async throws(StopVoiceRecordPlaybackUseCaseError)
}

public struct DefaultStopVoiceRecordPlaybackUseCase: StopVoiceRecordPlaybackUseCase {
    private let repository: VoiceRecordPlaybackRepository

    public init(repository: VoiceRecordPlaybackRepository) {
        self.repository = repository
    }

    public func execute() async throws(StopVoiceRecordPlaybackUseCaseError) {
        if Task.isCancelled { throw .cancelled }
        do {
            try await repository.stop()
        } catch {
            AppLogger.error(error)
            throw StopVoiceRecordPlaybackUseCaseError(error)
        }
    }
}
