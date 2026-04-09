@testable import Domain
import Foundation

public extension Folder {
    static func stub(
        id: UUID = UUID(),
        name: String = "Stub Folder",
        createdAt: Date = Date(),
        content: [VoiceNote] = [],
        isDeletable: Bool = true,
        deletedAt: Date? = nil
    ) -> Folder {
        Folder(
            id: id,
            name: name,
            createdAt: createdAt,
            content: content,
            isDeletable: isDeletable,
            deletedAt: deletedAt
        )
    }
}
