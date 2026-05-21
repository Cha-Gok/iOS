import Domain
import Core
import Observation

@MainActor
@Observable
public final class SettingViewModel {
    private let languageRepository: any LanguageRepository
    // MARK: - State
    private(set) var language: Language

    public init(
        languageRepository: any LanguageRepository
    ) {
        self.languageRepository = languageRepository
        self.language = languageRepository.fetchLanguage()
    }
    
    // MARK: - Actions
    
    func setLanguage(_ lang: Language) {
        self.language = lang
        languageRepository.saveLanguage(lang)
    }
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
