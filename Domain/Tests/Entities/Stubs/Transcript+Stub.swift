@testable import Domain
import Foundation

extension Transcript {
    static func stub(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        text: String = "mock transcript"
    ) -> Transcript {
        Transcript(id: id, createdAt: createdAt, text: text)
    }
}
