import Foundation

public enum AnalysisState: Sendable, Hashable {
    case pending
    case analyzing
    case completed
    case failed
}

public struct VoiceNote: Sendable, Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public let createdAt: Date
    public let updatedAt: Date
    public var folderID: UUID
    public let voiceRecord: VoiceRecord
    public let keywords: [Keyword]
    public var transcript: Transcript?
    public var summary: Summary?
    public var deletedAt: Date?
    public var analysisState: AnalysisState

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
        deletedAt: Date? = nil,
        analysisState: AnalysisState? = nil
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
        self.analysisState = analysisState ?? (summary != nil && transcript != nil ? .completed : .pending)
    }
}
