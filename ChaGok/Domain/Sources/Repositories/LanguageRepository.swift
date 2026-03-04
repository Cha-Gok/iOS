import Foundation

/// 언어 설정(Language)의 저장을 담당하는 리포지토리 프로토콜.
public protocol LanguageRepository: Sendable {
    /// 현재 설정된 언어를 가져옵니다.
    /// - Returns: 현재 설정된 언어 (기본값: ko)
    func fetchLanguage() -> Language

    /// 새로운 언어를 저장합니다.
    /// - Parameter language: 저장할 언어 (ko, en 등)
    func saveLanguage(_ language: Language)
}
