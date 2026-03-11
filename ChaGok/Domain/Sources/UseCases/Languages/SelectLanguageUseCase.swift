import Foundation
import Core

/// 앱에서 사용할 언어를 설정하는 유즈케이스 프로토콜
public protocol SelectLanguageUseCase: Sendable {
    /// 언어를 선택하고 저장합니다.
    /// - Parameter lang: 선택한 언어 (ko, en 등)
    /// - Throws: 언어 저장 실패 또는 작업 취소 시 (`SetLanguagesUseCaseError`)
    func execute(lang: Language) async throws(SetLanguagesUseCaseError)
}

public struct DefaultSelectLanguageUseCase: SelectLanguageUseCase {

    private let repository: LanguageRepository

    public init(repository: LanguageRepository) {
        self.repository = repository
    }

    public func execute(lang: Language) async throws(SetLanguagesUseCaseError) {
        typealias UseCaseError = SetLanguagesUseCaseError
        if Task.isCancelled { throw UseCaseError.cancelled }
        do {
            return try await repository.saveLanguage(lang)
        } catch {
            AppLogger.error(error)
            throw UseCaseError(error)
        }
    }
}
