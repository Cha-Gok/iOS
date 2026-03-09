import Foundation
import Core

/// 현재 설정된 언어를 가져오는 유즈케이스
public protocol FetchLanguageUseCase: Sendable {
    /// 현재 설정 된 언어를 가져옵니다
    /// - Returns: 설정 한 Language
    /// - Throws: 언어 조회 실패 시
    func execute() async throws(FetchLanguagesUseCaseError) -> Language
}

public struct DefaultFetchLanguageUseCase: FetchLanguageUseCase {
    private let repository: LanguageRepository

    public init(repository: LanguageRepository) {
        self.repository = repository
    }

    public func execute() async throws(FetchLanguagesUseCaseError) -> Language {
        typealias UseCaseError = FetchLanguagesUseCaseError
        if Task.isCancelled { throw UseCaseError.cancelled }
        do {
            return try await repository.fetchLanguage()
        } catch {
            AppLogger.error(error)
            switch error {
                case .cancelled: throw UseCaseError.cancelled
                case .notFound: throw UseCaseError.notFound
                case .unknown(let error): throw UseCaseError.unknown(error)
            }
        }
    }
}
