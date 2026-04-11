import Core
import Foundation

@MainActor
public protocol StopVoiceRecordPlaybackUseCase: Sendable {
    func execute() throws(StopVoiceRecordPlaybackUseCaseError)
}

@MainActor
public struct DefaultStopVoiceRecordPlaybackUseCase: StopVoiceRecordPlaybackUseCase {
    private let repository: VoiceRecordPlaybackRepository

    public init(repository: VoiceRecordPlaybackRepository) {
        self.repository = repository
    }

    public func execute() throws(StopVoiceRecordPlaybackUseCaseError) {
        do {
            try repository.stop()
        } catch {
            AppLogger.error(error)
            throw StopVoiceRecordPlaybackUseCaseError(error)
        }
    }
}
