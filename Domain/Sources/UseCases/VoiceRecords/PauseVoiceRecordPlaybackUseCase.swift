import Core
import Foundation

public protocol PauseVoiceRecordPlaybackUseCase: Sendable {
    func execute() async throws(PauseVoiceRecordPlaybackUseCaseError)
}

public struct DefaultPauseVoiceRecordPlaybackUseCase: PauseVoiceRecordPlaybackUseCase {
    private let repository: VoiceRecordPlaybackRepository

    public init(repository: VoiceRecordPlaybackRepository) {
        self.repository = repository
    }

    public func execute() async throws(PauseVoiceRecordPlaybackUseCaseError) {
        if Task.isCancelled { throw .cancelled }
        do {
            try await repository.pause()
        } catch {
            AppLogger.error(error)
            throw PauseVoiceRecordPlaybackUseCaseError(error)
        }
    }
}
