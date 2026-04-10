import Domain
import Foundation

public protocol AudioPlaybackService: Sendable {
    func preparePlayback(at fileURL: URL) async throws(AudioPlaybackServiceError) -> AsyncStream<AudioPlaybackState>
    func play() async throws(AudioPlaybackServiceError)
    func pause() async throws(AudioPlaybackServiceError)
    func seek(to time: TimeInterval) async throws(AudioPlaybackServiceError)
    func stop() async throws(AudioPlaybackServiceError)
}
