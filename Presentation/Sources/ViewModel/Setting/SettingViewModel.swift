import Domain
import Core
import Observation

@MainActor
@Observable
public final class SettingViewModel {
    private let languageRepository: any LanguageRepository
    private let mlxRepository: any AvailableModelSupportRepository

    // MARK: - State
    private(set) var language: Language
    private(set) var models: [ChaGokModelSupport] = []
    
    public init(
        languageRepository: any LanguageRepository,
        mlxRepository: any AvailableModelSupportRepository
    ) {
        self.languageRepository = languageRepository
        self.mlxRepository = mlxRepository
        self.language = languageRepository.fetchLanguage()
    }
    
    // MARK: - Setter / Getter
    
    func setLanguage(_ lang: Language) {
        self.language = lang
        languageRepository.saveLanguage(lang)
    }
    
    // MARK: - Actions
    
    func checkModels() {
        Task {
            
        }
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
