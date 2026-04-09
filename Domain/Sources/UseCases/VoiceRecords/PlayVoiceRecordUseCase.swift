import Core
import Foundation

public protocol PlayVoiceRecordUseCase: Sendable {
    func execute() async throws(PlayVoiceRecordUseCaseError)
}

public struct DefaultPlayVoiceRecordUseCase: PlayVoiceRecordUseCase {
    private let repository: VoiceRecordPlaybackRepository

    public init(repository: VoiceRecordPlaybackRepository) {
        self.repository = repository
    }

    public func execute() async throws(PlayVoiceRecordUseCaseError) {
        if Task.isCancelled { throw .cancelled }
        do {
            try await repository.play()
        } catch {
            AppLogger.error(error)
            throw PlayVoiceRecordUseCaseError(error)
        }
    }
}
