import Foundation

public struct Folder: Sendable, Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public let createdAt: Date
    public let content: [VoiceNote]
    public let kind: FolderKind
    public let deletedAt: Date?

    public init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date.now,
        content: [VoiceNote] = [],
        kind: FolderKind = .custom,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.content = content
        self.kind = kind
        self.deletedAt = deletedAt
    }
}
