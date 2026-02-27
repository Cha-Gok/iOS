import Foundation

public struct Folder: Sendable {
    public let id: UUID
    public let path: URL
    public let name: String
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        path: URL,
        name: String,
        createdAt: Date,
    ) {
        self.id = id
        self.path = path
        self.name = name
        self.createdAt = createdAt
    }
}
