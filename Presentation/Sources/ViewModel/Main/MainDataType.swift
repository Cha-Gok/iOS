import Domain
import Foundation
import Observation

public enum MainSection: Hashable, Sendable {
    case list
    case groupedList(MainListDateGroup)
    case emptyList
}

public enum MainListDateGroup: Int, Hashable, Sendable, CaseIterable {
    case today
    case recentSevenDays
    case older

    var title: String {
        switch self {
        case .today: return "오늘"
        case .recentSevenDays: return "최근 7일"
        case .older: return "이전"
        }
    }
}

public struct CategoryToggle: Hashable, Sendable {
    public let id: UUID = UUID()
    public let imageName: String
    public let title: String
    public var items: [ContentItem]

    public init(imageName: String, title: String, items: [ContentItem]) {
        self.imageName = imageName
        self.title = title
        self.items = items
    }

    public static func == (lhs: CategoryToggle, rhs: CategoryToggle) -> Bool {
        lhs.id == rhs.id && lhs.items == rhs.items
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(items)
    }
}

public enum MainCellItem: Hashable, Sendable {
    case list(ContentItem)
    case emptyList
}
