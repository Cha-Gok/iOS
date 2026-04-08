import Foundation

public struct VoiceNote: Sendable, Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public let createdAt: Date
    public let updatedAt: Date
    public let folderID: UUID
    public let voiceRecord: VoiceRecord
    public let keywords: [Keyword]
    public var transcript: Transcript?
    public var summary: Summary?
    public var deletedAt: Date?

    public init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date.now,
        updatedAt: Date = Date.now,
        folderID: UUID,
        voiceRecord: VoiceRecord,
        keywords: [Keyword] = [],
        transcript: Transcript? = nil,
        summary: Summary? = nil,
        deletedAt: Date? = nil
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
        self.deletedAt = deletedAt
    }
}
