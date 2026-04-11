import Core
import Domain
import Foundation

@MainActor
public struct DefaultVoiceRecordPlaybackRepository: VoiceRecordPlaybackRepository {
    private let audioPlaybackService: any AudioPlaybackService

    public init(audioPlaybackService: any AudioPlaybackService) {
        self.audioPlaybackService = audioPlaybackService
    }

    public func prepare(audioFileURL: URL) throws(VoiceRecordPlaybackRepositoryError)
        -> AsyncStream<AudioPlaybackState>
    {
        if Task.isCancelled { throw .cancelled }
        do {
            return try audioPlaybackService.preparePlayback(at: audioFileURL)
        } catch {
            AppLogger.error(error)
            throw VoiceRecordPlaybackRepositoryError(error)
        }
    }

    public func play() throws(VoiceRecordPlaybackRepositoryError) {
        if Task.isCancelled { throw .cancelled }
        do {
            try audioPlaybackService.play()
        } catch {
            AppLogger.error(error)
            throw VoiceRecordPlaybackRepositoryError(error)
        }
    }

    public func pause() throws(VoiceRecordPlaybackRepositoryError) {
        if Task.isCancelled { throw .cancelled }
        do {
            try audioPlaybackService.pause()
        } catch {
            AppLogger.error(error)
            throw VoiceRecordPlaybackRepositoryError(error)
        }
    }

    public func seek(to time: TimeInterval) throws(VoiceRecordPlaybackRepositoryError) {
        if Task.isCancelled { throw .cancelled }
        do {
            try audioPlaybackService.seek(to: time)
        } catch {
            AppLogger.error(error)
            throw VoiceRecordPlaybackRepositoryError(error)
        }
    }

    public func stop() throws(VoiceRecordPlaybackRepositoryError) {
        if Task.isCancelled { throw .cancelled }
        do {
            try audioPlaybackService.stop()
        } catch {
            AppLogger.error(error)
            throw VoiceRecordPlaybackRepositoryError(error)
        }
    }
}
