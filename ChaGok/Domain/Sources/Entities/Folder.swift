import Foundation

public struct Folder {
    public let id: String
    public let path: URL
    public let name: String
    public let createdAt: Date

    public init(
        id: String,
        path: URL,
        name: String,
        createdAt: Date
    ) {
        self.id = id
        self.path = path
        self.name = name
        self.createdAt = createdAt
    }
}
