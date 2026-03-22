import Domain

public protocol LanguageService: Sendable {
    /// 저장된 앱 언어 설정 데이터를 조회합니다.
    /// - Returns: 식별된 언어 정보가 담긴 데이터 (예: "ko", "en").
    /// - Throws: 데이터가 없는 경우 .notFound 에러를 발생시킵니다.
    func fetchLanguage() throws(LanguageServiceError) -> String

    /// 앱 언어 설정 데이터를 저장합니다.
    /// - Parameter language: 저장하고자 하는 언어 식별 데이터
    func saveLanguage(_ language: String)
}
