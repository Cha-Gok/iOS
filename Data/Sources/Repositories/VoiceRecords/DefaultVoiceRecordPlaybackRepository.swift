import Core
import Domain
import Foundation

@MainActor
public struct DefaultVoiceRecordPlaybackRepository: VoiceRecordPlaybackRepository {
    private let audioPlaybackService: any AudioPlaybackService
    private let storageService: any StorageService

    public init(audioPlaybackService: any AudioPlaybackService, storageService: any StorageService) {
        self.audioPlaybackService = audioPlaybackService
        self.storageService = storageService
    }

    public func prepare(audioFilePath: String) throws(VoiceRecordPlaybackRepositoryError)
        -> AsyncStream<AudioPlaybackState>
    {
        let absoluteURL = storageService.absoluteURL(for: audioFilePath)
        do {
            return try audioPlaybackService.preparePlayback(at: absoluteURL)
        } catch {
            AppLogger.error(error)
            throw VoiceRecordPlaybackRepositoryError(error)
        }
    }

    public func play() throws(VoiceRecordPlaybackRepositoryError) {
        do {
            try audioPlaybackService.play()
        } catch {
            AppLogger.error(error)
            throw VoiceRecordPlaybackRepositoryError(error)
        }
    }

    public func pause() throws(VoiceRecordPlaybackRepositoryError) {
        do {
            try audioPlaybackService.pause()
        } catch {
            AppLogger.error(error)
            throw VoiceRecordPlaybackRepositoryError(error)
        }
    }

    public func seek(to time: TimeInterval) throws(VoiceRecordPlaybackRepositoryError) {
        do {
            try audioPlaybackService.seek(to: time)
        } catch {
            AppLogger.error(error)
            throw VoiceRecordPlaybackRepositoryError(error)
        }
    }

    public func stop() throws(VoiceRecordPlaybackRepositoryError) {
        do {
            try audioPlaybackService.stop()
        } catch {
            AppLogger.error(error)
            throw VoiceRecordPlaybackRepositoryError(error)
        }
    }
}
