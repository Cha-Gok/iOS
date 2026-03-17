import Foundation

@testable import Domain

extension Keyword {
    static func stub(
        id: UUID = UUID(),
        noteId: UUID = UUID(),
        word: String = "mock keyword"
    ) -> Keyword {
        Keyword(id: id, noteId: noteId, word: word)
    }
}
