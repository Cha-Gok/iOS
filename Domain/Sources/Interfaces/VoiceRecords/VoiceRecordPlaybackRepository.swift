import Foundation

@MainActor
public protocol VoiceRecordPlaybackRepository: Sendable {
    func prepare(audioFilePath: String) throws(VoiceRecordPlaybackRepositoryError) -> AsyncStream<AudioPlaybackState>
    func play() throws(VoiceRecordPlaybackRepositoryError)
    func pause() throws(VoiceRecordPlaybackRepositoryError)
    func seek(to time: TimeInterval) throws(VoiceRecordPlaybackRepositoryError)
    func stop() throws(VoiceRecordPlaybackRepositoryError)
}
