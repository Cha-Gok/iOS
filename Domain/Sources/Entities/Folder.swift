import Foundation

public struct Folder: Sendable, Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let createdAt: Date
    public let content: [VoiceNote]
    public let isDeletable: Bool
    public let deletedAt: Date?

    public init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date.now,
        content: [VoiceNote] = [],
        isDeletable: Bool = true,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.content = content
        self.isDeletable = isDeletable
        self.deletedAt = deletedAt
    }
}
