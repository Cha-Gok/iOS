import Domain
import Foundation

public struct LanguageSettingService: LanguageService {
    public init() {}

    public func fetchLanguage() throws(LanguageServiceError) -> String {
        // UserDefaults에서 저장된 언어 코드를 조회합니다.
        guard let fetchResult = UserDefaults.standard.string(forKey: Policy.appSelectedLanguageKey)
        else {
            throw .notFound
        }
        return fetchResult
    }

    public func saveLanguage(_ language: String) {
        // UserDefaults에 언어 코드를 저장합니다.
        UserDefaults.standard.set(language, forKey: Policy.appSelectedLanguageKey)
    }
}
