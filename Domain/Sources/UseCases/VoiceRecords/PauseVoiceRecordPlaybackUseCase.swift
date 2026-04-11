import Core
import Foundation

@MainActor
public protocol PauseVoiceRecordPlaybackUseCase: Sendable {
    func execute() throws(PauseVoiceRecordPlaybackUseCaseError)
}

@MainActor
public struct DefaultPauseVoiceRecordPlaybackUseCase: PauseVoiceRecordPlaybackUseCase {
    private let repository: VoiceRecordPlaybackRepository

    public init(repository: VoiceRecordPlaybackRepository) {
        self.repository = repository
    }

    public func execute() throws(PauseVoiceRecordPlaybackUseCaseError) {
        do {
            try repository.pause()
        } catch {
            AppLogger.error(error)
            throw PauseVoiceRecordPlaybackUseCaseError(error)
        }
    }
}
