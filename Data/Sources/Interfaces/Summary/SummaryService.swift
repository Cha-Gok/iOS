import Domain
import Foundation

/// 요약 및 키워드 추출 기능을 제공하는 서비스 인터페이스.
public protocol SummaryService: Sendable {
    /// 텍스트에서 키워드와 요약을 추출합니다.
    /// - Parameter text: 원본 전사 데이터 텍스트
    /// - Returns: 키워드 목록과 요약 텍스트의 튜플
    /// - Throws: `SummaryServiceError`
    func summarize(text: String, language: Language) async throws(SummaryServiceError)
        -> (keywords: [String], summary: String)
}
