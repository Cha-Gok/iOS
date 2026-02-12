import Foundation

public struct Transcript {
    public let id: String
    public let createdAt: Date
    public let text: String

    public init(
        id: String,
        createdAt: Date,
        text: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.text = text
    }
}
