@testable import Domain
import Foundation

public extension Transcript {
    static func stub(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        text: String = "mock transcript"
    ) -> Transcript {
        Transcript(id: id, createdAt: createdAt, text: text)
    }
}
