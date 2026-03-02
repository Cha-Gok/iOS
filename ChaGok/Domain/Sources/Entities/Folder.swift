import Foundation

public struct Folder {
    public let id: UUID
    public let path: URL
    public let name: String
    public let createdAt: Date
    public let content: [VoiceNote]

    public init(
        id: UUID = UUID(),
        path: URL,
        name: String,
        createdAt: Date = Date.now,
        content: [VoiceNote] = []
    ) {
        self.id = id
        self.path = path
        self.name = name
        self.createdAt = createdAt
        self.content = content
    }
}

extension Folder: Sendable {}
