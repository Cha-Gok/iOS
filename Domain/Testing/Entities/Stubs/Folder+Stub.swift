@testable import Domain
import Foundation

public extension Folder {
    static func stub(
        id: UUID = UUID(),
        name: String = "Stub Folder",
        createdAt: Date = Date(),
        voiceNoteIDs: [UUID] = [],
        kind: FolderKind = .custom,
        deletedAt: Date? = nil
    ) -> Folder {
        Folder(
            id: id,
            name: name,
            createdAt: createdAt,
            voiceNoteIDs: voiceNoteIDs,
            kind: kind,
            deletedAt: deletedAt
        )
    }
}
