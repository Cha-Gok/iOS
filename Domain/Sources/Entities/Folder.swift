import Foundation

public struct Folder: Sendable, Identifiable, Hashable {
    public let id: UUID
    public var name: String
    public let createdAt: Date
    /// 폴더에 속한 살아있는 보이스 노트 ID 목록 (휴지통 노트 제외).
    public let voiceNoteIDs: [UUID]
    public let kind: FolderKind
    public var deletedAt: Date?
    /// 부모 폴더 ID. 일반 root 폴더는 `nil`, 휴지통 안의 폴더는 휴지통 폴더 ID.
    public var parentID: UUID?

    public init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date.now,
        voiceNoteIDs: [UUID] = [],
        kind: FolderKind = .custom,
        deletedAt: Date? = nil,
        parentID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.voiceNoteIDs = voiceNoteIDs
        self.kind = kind
        self.deletedAt = deletedAt
        self.parentID = parentID
    }
}
