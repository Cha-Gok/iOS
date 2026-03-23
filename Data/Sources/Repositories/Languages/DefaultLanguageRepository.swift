import Domain
import Foundation

public struct DefaultLanguageRepository: LanguageRepository {
  private let service: any LanguageService

  public init(service: any LanguageService) {
    self.service = service
  }

  public func fetchLanguage() async throws(FetchLanguagesRepositoryError) -> Language {
    if Task.isCancelled { throw FetchLanguagesRepositoryError.cancelled }

    guard let rawLanguage = try? service.fetchLanguage() else {
      return .ko
    }
    return Language(rawValue: rawLanguage) ?? .ko
  }

  public func saveLanguage(_ language: Language) async throws(SetLanguagesRepositoryError) {
    if Task.isCancelled { throw .cancelled }
    service.saveLanguage(language.rawValue)
  }
}
