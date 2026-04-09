@testable import Domain
import Foundation

public extension Keyword {
    static func stub(
        id: UUID = UUID(),
        noteID: UUID = UUID(),
        word: String = "mock keyword"
    ) -> Keyword {
        Keyword(id: id, noteID: noteID, word: word)
    }
}
