import Foundation

public struct VoiceNote: Sendable {
    public let id: UUID
    public let title: String
    public let createdAt: Date
    public let updatedAt: Date
    public let folderId: UUID
    public let voiceRecord: VoiceRecord
    public let keywords: [Keyword]
    public var transcript: Transcript?
    public var summary: Summary?

    public init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date,
        updatedAt: Date,
        folderId: UUID,
        voiceRecord: VoiceRecord,
        keywords: [Keyword],
        transcript: Transcript? = nil,
        summary: Summary? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.folderId = folderId
        self.voiceRecord = voiceRecord
        self.keywords = keywords
        self.transcript = transcript
        self.summary = summary
    }
}
