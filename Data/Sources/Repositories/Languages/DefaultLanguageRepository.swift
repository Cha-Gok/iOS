import Domain
import Foundation

public struct DefaultLanguageRepository: LanguageRepository {
    private let store: any KeyValueStoreService

    public init(store: any KeyValueStoreService) {
        self.store = store
    }

    public func fetchLanguage() -> Language {
        guard let raw = store.string(forKey: Policy.appSelectedLanguageKey) else { return .ko }
        return Language(rawValue: raw) ?? .ko
    }

    public func saveLanguage(_ language: Language) {
        store.set(language.rawValue, forKey: Policy.appSelectedLanguageKey)
    }
}
