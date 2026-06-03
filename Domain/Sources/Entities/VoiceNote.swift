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

    public enum BindingKey {
        case progress
        case success
        case failed
    }

    public var bindingValue: BindingKey {
        switch self {
        case .pending, .transcribing, .transcribed, .regenerating, .summarizing:
            .progress
        case .completed:
            .success
        case .transcriptionFailed, .summarizationFailed:
            .failed
        }
    }
}

public struct VoiceNote: Sendable, Identifiable, Hashable {
    public let id: UUID
    public var title: String
    public let createdAt: Date
    public var updatedAt: Date
    public var folderID: UUID
    public let voiceRecord: VoiceRecord
    public let keywords: [Keyword]
    public var transcript: Transcript?
    public var summary: Summary?
    public var deletedAt: Date?
    /// 휴지통에 단독 진입했을 때 복원 destination이 되는 원본 폴더 ID. 단독 진입 외에는 `nil`.
    /// 폴더 cascade 삭제는 노트 자체를 옮기지 않으므로 본 필드를 세팅하지 않는다.
    public var originalFolderID: UUID?
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
        originalFolderID: UUID? = nil,
        analysisState: AnalysisState
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
        self.originalFolderID = originalFolderID
        self.analysisState = analysisState
    }
}

public extension VoiceNote {
    /// 요약 생성 이후 스크립트가 수정되어 요약이 최신 상태가 아닌지 여부.
    var isSummaryOutdated: Bool {
        guard let summary, let transcript else { return false }
        return summary.createdAt < transcript.updatedAt
    }
}
