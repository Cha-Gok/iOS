import Foundation

public struct Keyword {
    public let id: String
    public let noteId: String
    public let word: String

    public init(
        id: String,
        noteId: String,
        word: String
    ) {
        self.id = id
        self.noteId = noteId
        self.word = word
    }
}
