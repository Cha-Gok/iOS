import Core
import Foundation

@MainActor
public protocol SeekVoiceRecordPlaybackUseCase: Sendable {
    func execute(time: TimeInterval) throws(SeekVoiceRecordPlaybackUseCaseError)
}

@MainActor
public struct DefaultSeekVoiceRecordPlaybackUseCase: SeekVoiceRecordPlaybackUseCase {
    private let repository: VoiceRecordPlaybackRepository

    public init(repository: VoiceRecordPlaybackRepository) {
        self.repository = repository
    }

    public func execute(time: TimeInterval) throws(SeekVoiceRecordPlaybackUseCaseError) {
        if Task.isCancelled { throw .cancelled }
        do {
            try repository.seek(to: time)
        } catch {
            AppLogger.error(error)
            throw SeekVoiceRecordPlaybackUseCaseError(error)
        }
    }
}
