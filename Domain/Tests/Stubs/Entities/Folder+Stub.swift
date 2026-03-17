import Foundation
@testable import Domain

extension Folder {
    static func stub(
        id: UUID = UUID(),
        path: URL = URL(fileURLWithPath: "/test"),
        name: String = "Stub Folder",
        createdAt: Date = Date(),
        content: [VoiceNote] = [],
        isDeletable: Bool = true,
        deletedAt: Date? = nil
    ) -> Folder {
        Folder(
            id: id,
            path: path,
            name: name,
            createdAt: createdAt,
            content: content,
            isDeletable: isDeletable,
            deletedAt: deletedAt
        )
    }
}
