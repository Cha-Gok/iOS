import Foundation

public enum AnalysisState: String, Sendable, Hashable {
    case pending
    case transcribing
    case transcriptionFailed
    case transcribed
    case summarizing
    case regenerating
    case completed
    case summarizationFailed
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
        if let analysisState {
            self.analysisState = analysisState
        } else if summary != nil, transcript != nil {
            self.analysisState = .completed
        } else if transcript != nil {
            self.analysisState = .transcribed
        } else {
            self.analysisState = .pending
        }
    }
}
