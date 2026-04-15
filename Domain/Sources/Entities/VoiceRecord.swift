import Foundation

public struct VoiceRecord: Sendable, Identifiable, Hashable {
    public let id: UUID
    public let createdAt: Date
    public let audioFilePath: String
    public let duration: Double

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date.now,
        audioFilePath: String,
        duration: Double
    ) {
        self.id = id
        self.createdAt = createdAt
        self.audioFilePath = audioFilePath
        self.duration = duration
    }
}
