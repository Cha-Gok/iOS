import Domain
import Foundation

public struct DefaultLanguageRepository: LanguageRepository {
    private let store: any KeyValueStoreService

    public init(store: any KeyValueStoreService) {
        self.store = store
    }

    public func fetchLanguage() async throws(FetchLanguagesRepositoryError) -> Language {
        if Task.isCancelled { throw .cancelled }
        guard let raw = store.string(forKey: Policy.appSelectedLanguageKey) else { return .ko }
        return Language(rawValue: raw) ?? .ko
    }

    public func saveLanguage(_ language: Language) async throws(SetLanguagesRepositoryError) {
        if Task.isCancelled { throw .cancelled }
        store.set(language.rawValue, forKey: Policy.appSelectedLanguageKey)
    }
}
