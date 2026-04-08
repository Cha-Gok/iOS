import Foundation

public struct Keyword: Sendable, Identifiable, Hashable {
    public let id: UUID
    public let noteID: UUID
    public let word: String

    public init(
        id: UUID = UUID(),
        noteID: UUID,
        word: String
    ) {
        self.id = id
        self.noteID = noteID
        self.word = word
    }
}
