import Foundation

public struct Transcript: Sendable {
    public let id: UUID
    public let createdAt: Date
    public let text: String

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date.now,
        text: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.text = text
    }
}
