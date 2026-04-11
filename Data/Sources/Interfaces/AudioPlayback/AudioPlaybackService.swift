import Domain
import Foundation

@MainActor
public protocol AudioPlaybackService: Sendable {
    func preparePlayback(at fileURL: URL) throws(AudioPlaybackServiceError) -> AsyncStream<AudioPlaybackState>
    func play() throws(AudioPlaybackServiceError)
    func pause() throws(AudioPlaybackServiceError)
    func seek(to time: TimeInterval) throws(AudioPlaybackServiceError)
    func stop() throws(AudioPlaybackServiceError)
}
