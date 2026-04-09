@testable import Domain
import Foundation

public extension Summary {
    static func stub(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        text: String = "mock summary"
    ) -> Summary {
        Summary(id: id, createdAt: createdAt, text: text)
    }
}
