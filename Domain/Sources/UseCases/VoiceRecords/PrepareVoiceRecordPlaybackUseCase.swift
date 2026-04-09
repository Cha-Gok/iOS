import Core
import Foundation

public protocol PrepareVoiceRecordPlaybackUseCase: Sendable {
    func execute(audioFileURL: URL) async throws(PrepareVoiceRecordPlaybackUseCaseError)
        -> AsyncStream<AudioPlaybackState>
}

public struct DefaultPrepareVoiceRecordPlaybackUseCase: PrepareVoiceRecordPlaybackUseCase {
    private let repository: VoiceRecordPlaybackRepository

    public init(repository: VoiceRecordPlaybackRepository) {
        self.repository = repository
    }

    public func execute(audioFileURL: URL) async throws(PrepareVoiceRecordPlaybackUseCaseError)
        -> AsyncStream<AudioPlaybackState>
    {
        if Task.isCancelled { throw .cancelled }
        do {
            return try await repository.prepare(audioFileURL: audioFileURL)
        } catch {
            AppLogger.error(error)
            throw PrepareVoiceRecordPlaybackUseCaseError(error)
        }
    }
}
