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
    /// 휴지통에 들어갔을 때 복원 destination이 되는 원본 폴더 ID. 휴지통 외 상태에서는 `nil`.
    public var originalFolderID: UUID?
    /// `true`면 부모 폴더가 삭제되며 cascade로 휴지통에 들어왔음을 의미. 단독 삭제는 `false`.
    public var deletedWithFolder: Bool
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
        deletedWithFolder: Bool = false,
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
        self.deletedWithFolder = deletedWithFolder
        self.analysisState = analysisState
    }
}

public extension VoiceNote {
    /// 일부 필드를 변경한 복사본을 반환합니다.
    ///
    /// 각 파라미터에 `nil`을 전달하거나 생략하면 기존 값을 유지합니다.
    /// Optional 필드(`transcript`, `summary`, `deletedAt`)를 `nil`로 비우는 용도는 지원하지 않습니다.
    /// - Parameter updatedAt: 수정 시각. 기본값은 `.now`입니다.
    func copyWith(
        title: String? = nil,
        updatedAt: Date = .now,
        folderID: UUID? = nil,
        transcript: Transcript? = nil,
        summary: Summary? = nil,
        deletedAt: Date? = nil,
        originalFolderID: UUID? = nil,
        deletedWithFolder: Bool? = nil,
        analysisState: AnalysisState? = nil
    ) -> VoiceNote {
        VoiceNote(
            id: id,
            title: title ?? self.title,
            createdAt: createdAt,
            updatedAt: updatedAt,
            folderID: folderID ?? self.folderID,
            voiceRecord: voiceRecord,
            keywords: keywords,
            transcript: transcript ?? self.transcript,
            summary: summary ?? self.summary,
            deletedAt: deletedAt ?? self.deletedAt,
            originalFolderID: originalFolderID ?? self.originalFolderID,
            deletedWithFolder: deletedWithFolder ?? self.deletedWithFolder,
            analysisState: analysisState ?? self.analysisState
        )
    }
}
