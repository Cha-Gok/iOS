import Domain
import Foundation
import Observation

public enum MainSection: Hashable, Sendable {
    case category
    case list
}

public enum LibraryItem: Hashable, Sendable {
    case folder(Folder)
    case voiceNote(VoiceNote)

    public var id: UUID {
        switch self {
        case .folder(let folder): return folder.id
        case .voiceNote(let voiceNote): return voiceNote.id
        }
    }
}

public struct CategoryToggle: Hashable, Sendable {
    public let id: UUID = UUID()
    public let imageName: String
    public let title: String
    public var items: [LibraryItem]

    public init(imageName: String, title: String, items: [LibraryItem]) {
        self.imageName = imageName
        self.title = title
        self.items = items
    }

    public static func == (lhs: CategoryToggle, rhs: CategoryToggle) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public enum MainCellItem: Hashable, Sendable {
    case category(CategoryToggle)
    case list(LibraryItem)
    case emptyList
}
