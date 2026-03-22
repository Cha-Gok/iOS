import Foundation

public struct Keyword: Sendable, Identifiable {
    public let id: UUID
    public let noteId: UUID
    public let word: String

    public init(
        id: UUID = UUID(),
        noteId: UUID,
        word: String
    ) {
        self.id = id
        self.noteId = noteId
        self.word = word
    }
}
