import Foundation

public struct Summary: Sendable {
    public let id: UUID
    public let createdAt: Date
    public let text: String

    public init(
        id: UUID = UUID(),
        createdAt: Date,
        text: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.text = text
    }
}
