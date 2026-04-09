import Foundation

public protocol VoiceRecordPlaybackRepository: Sendable {
    func prepare(audioFileURL: URL) async throws(VoiceRecordPlaybackRepositoryError) -> AsyncStream<AudioPlaybackState>
    func play() async throws(VoiceRecordPlaybackRepositoryError)
    func pause() async throws(VoiceRecordPlaybackRepositoryError)
    func seek(to time: TimeInterval) async throws(VoiceRecordPlaybackRepositoryError)
    func stop() async throws(VoiceRecordPlaybackRepositoryError)
}
