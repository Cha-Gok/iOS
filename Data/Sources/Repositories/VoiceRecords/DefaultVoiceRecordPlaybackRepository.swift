import Core
import Domain
import Foundation

public struct DefaultVoiceRecordPlaybackRepository: VoiceRecordPlaybackRepository {
    private let audioPlaybackService: any AudioPlaybackService

    public init(audioPlaybackService: any AudioPlaybackService) {
        self.audioPlaybackService = audioPlaybackService
    }

    public func prepare(audioFileURL: URL) async throws(VoiceRecordPlaybackRepositoryError)
        -> AsyncStream<AudioPlaybackState>
    {
        if Task.isCancelled { throw .cancelled }
        do {
            return try await audioPlaybackService.preparePlayback(at: audioFileURL)
        } catch {
            AppLogger.error(error)
            throw VoiceRecordPlaybackRepositoryError(error)
        }
    }

    public func play() async throws(VoiceRecordPlaybackRepositoryError) {
        if Task.isCancelled { throw .cancelled }
        do {
            try await audioPlaybackService.play()
        } catch {
            AppLogger.error(error)
            throw VoiceRecordPlaybackRepositoryError(error)
        }
    }

    public func pause() async throws(VoiceRecordPlaybackRepositoryError) {
        if Task.isCancelled { throw .cancelled }
        do {
            try await audioPlaybackService.pause()
        } catch {
            AppLogger.error(error)
            throw VoiceRecordPlaybackRepositoryError(error)
        }
    }

    public func seek(to time: TimeInterval) async throws(VoiceRecordPlaybackRepositoryError) {
        if Task.isCancelled { throw .cancelled }
        do {
            try await audioPlaybackService.seek(to: time)
        } catch {
            AppLogger.error(error)
            throw VoiceRecordPlaybackRepositoryError(error)
        }
    }

    public func stop() async throws(VoiceRecordPlaybackRepositoryError) {
        if Task.isCancelled { throw .cancelled }
        do {
            try await audioPlaybackService.stop()
        } catch {
            AppLogger.error(error)
            throw VoiceRecordPlaybackRepositoryError(error)
        }
    }
}
