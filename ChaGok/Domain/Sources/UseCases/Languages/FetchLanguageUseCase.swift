import Foundation

/// 현재 설정된 언어를 가져오는 유즈케이스
public protocol FetchLanguageUseCase: Sendable {
    /// 현재 설정 된 언어를 가져옵니다
    /// - Returns: 설정 한 Language
    func execute() -> Language
}

public struct DefaultFetchLanguageUseCase: FetchLanguageUseCase {
    private let repository: LanguageRepository

    public init(repository: LanguageRepository) {
        self.repository = repository
    }

    public func execute() -> Language {
        repository.fetchLanguage()
    }
}
