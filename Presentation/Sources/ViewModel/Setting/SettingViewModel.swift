import Domain
import Core
import Observation

@MainActor
@Observable
public final class SettingViewModel {
    public init() {}
}

// MARK: - Data

extension SettingViewModel {
    enum Section: Hashable {
        case lang
        case model
        case label
    }
    
    struct Item: Hashable {
        let title: String
        let subTitle: String?
        let data: ItemData
    }
    
    enum ItemData: Hashable {
        case lang(Language)
        case model(ChaGokModelSupport)
        case none
    }
}
