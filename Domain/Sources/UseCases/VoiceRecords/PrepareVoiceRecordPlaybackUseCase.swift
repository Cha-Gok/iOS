import Core
import Foundation

@MainActor
public protocol PrepareVoiceRecordPlaybackUseCase: Sendable {
    func execute(audioFileURL: URL) throws(PrepareVoiceRecordPlaybackUseCaseError)
        -> AsyncStream<AudioPlaybackState>
}

@MainActor
public struct DefaultPrepareVoiceRecordPlaybackUseCase: PrepareVoiceRecordPlaybackUseCase {
    private let repository: VoiceRecordPlaybackRepository

    public init(repository: VoiceRecordPlaybackRepository) {
        self.repository = repository
    }

    public func execute(audioFileURL: URL) throws(PrepareVoiceRecordPlaybackUseCaseError)
        -> AsyncStream<AudioPlaybackState>
    {
        if Task.isCancelled { throw .cancelled }
        do {
            return try repository.prepare(audioFileURL: audioFileURL)
        } catch {
            AppLogger.error(error)
            throw PrepareVoiceRecordPlaybackUseCaseError(error)
        }
    }
}
