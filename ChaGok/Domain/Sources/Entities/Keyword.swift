import Foundation

public struct Keyword: Sendable {
    public let id: UUID
    public let noteId: String
    public let word: String

    public init(
        id: UUID = UUID(),
        noteId: String,
        word: String
    ) {
        self.id = id
        self.noteId = noteId
        self.word = word
    }
}
