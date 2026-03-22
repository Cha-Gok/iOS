import Domain
import Foundation

public struct DefaultLanguageRepository: LanguageRepository {
    private let service: any LanguageService

    public init(service: any LanguageService) {
        self.service = service
    }

    public func fetchLanguage() async throws(FetchLanguagesRepositoryError) -> Language {
        do {
            if Task.isCancelled { throw FetchLanguagesRepositoryError.cancelled }
            let rawLanguage = try service.fetchLanguage()
            return Language(rawValue: rawLanguage) ?? .ko
        } catch let error as FetchLanguagesRepositoryError {
            throw error
        } catch is LanguageServiceError {
            return .ko
        } catch {
            throw .unknown(error)
        }
    }

    public func saveLanguage(_ language: Language) async throws(SetLanguagesRepositoryError) {
        // 1. Task 취소 여부만 체크 (필요 시)
        if Task.isCancelled { throw .cancelled }
        service.saveLanguage(language.rawValue)
    }
}
