import Foundation

public struct RecordedAudio: Sendable {
    public let createdAt: Date
    public let audioFilePath: URL
    public let duration: Double

    public init(
        createdAt: Date,
        audioFilePath: URL,
        duration: Double
    ) {
        self.createdAt = createdAt
        self.audioFilePath = audioFilePath
        self.duration = duration
    }
}
