import Core
import Foundation

@MainActor
public protocol PrepareVoiceRecordPlaybackUseCase: Sendable {
    func execute(audioFilePath: String) throws(PrepareVoiceRecordPlaybackUseCaseError)
        -> AsyncStream<AudioPlaybackState>
}

@MainActor
public struct DefaultPrepareVoiceRecordPlaybackUseCase: PrepareVoiceRecordPlaybackUseCase {
    private let repository: VoiceRecordPlaybackRepository

    public init(repository: VoiceRecordPlaybackRepository) {
        self.repository = repository
    }

    public func execute(audioFilePath: String) throws(PrepareVoiceRecordPlaybackUseCaseError)
        -> AsyncStream<AudioPlaybackState>
    {
        do {
            return try repository.prepare(audioFilePath: audioFilePath)
        } catch {
            AppLogger.error(error)
            throw PrepareVoiceRecordPlaybackUseCaseError(error)
        }
    }
}
