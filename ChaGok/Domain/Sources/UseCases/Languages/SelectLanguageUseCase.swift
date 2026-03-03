import Foundation

/// 앱에서 사용할 언어를 설정하는 유즈케이스 프로토콜
public protocol SelectLanguageUseCase: Sendable {
    /// 언어를 선택하고 저장합니다.
    /// - Parameter lang: 선택한 언어 (ko, en 등)
    func execute(lang: Language)
}

public struct DefaultSelectLanguageUseCase: SelectLanguageUseCase {

    private let repository: LanguageRepository

    public init(repository: LanguageRepository) {
        self.repository = repository
    }

    public func execute(lang: Language) {
        repository.saveLanguage(lang)
    }
}
