import Core
import Foundation

public protocol SeekVoiceRecordPlaybackUseCase: Sendable {
    func execute(time: TimeInterval) async throws(SeekVoiceRecordPlaybackUseCaseError)
}

public struct DefaultSeekVoiceRecordPlaybackUseCase: SeekVoiceRecordPlaybackUseCase {
    private let repository: VoiceRecordPlaybackRepository

    public init(repository: VoiceRecordPlaybackRepository) {
        self.repository = repository
    }

    public func execute(time: TimeInterval) async throws(SeekVoiceRecordPlaybackUseCaseError) {
        if Task.isCancelled { throw .cancelled }
        do {
            try await repository.seek(to: time)
        } catch {
            AppLogger.error(error)
            throw SeekVoiceRecordPlaybackUseCaseError(error)
        }
    }
}
