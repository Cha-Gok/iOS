import Foundation

public struct VoiceNote {
    public let id: String
    public let title: String
    public let createdAt: Date
    public let updatedAt: Date
    public let folderID: String
    public let voiceRecord: VoiceRecord
    public let keywords: [Keyword]
    public var transcript: Transcript?
    public var summary: Summary?
    
    public init(
        id: String,
        title: String,
        createdAt: Date,
        updatedAt: Date,
        folderID: String,
        voiceRecord: VoiceRecord,
        keywords: [Keyword],
        transcript: Transcript? = nil,
        summary: Summary? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.folderID = folderID
        self.voiceRecord = voiceRecord
        self.keywords = keywords
        self.transcript = transcript
        self.summary = summary
    }
}
