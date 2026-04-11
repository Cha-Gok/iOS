import Core
import Foundation

@MainActor
public protocol PlayVoiceRecordUseCase: Sendable {
    func execute() throws(PlayVoiceRecordUseCaseError)
}

@MainActor
public struct DefaultPlayVoiceRecordUseCase: PlayVoiceRecordUseCase {
    private let repository: VoiceRecordPlaybackRepository

    public init(repository: VoiceRecordPlaybackRepository) {
        self.repository = repository
    }

    public func execute() throws(PlayVoiceRecordUseCaseError) {
        do {
            try repository.play()
        } catch {
            AppLogger.error(error)
            throw PlayVoiceRecordUseCaseError(error)
        }
    }
}
