import Foundation

public struct VoiceRecord {
    public let id: String
    public let createdAt: Date
    public let audioFilePath: URL
    public let duration: Double
    
    public init(
        id: String,
        createdAt: Date,
        audioFilePath: URL,
        duration: Double
    ) {
        self.id = id
        self.createdAt = createdAt
        self.audioFilePath = audioFilePath
        self.duration = duration
    }
}
