import Foundation

/// 요약(Summary) 및 분석을 담당하는 리포지토리 프로토콜.
public protocol SummaryRepository: Sendable {
    /// 전사 텍스트를 분석하여 키워드와 요약을 생성합니다.
    /// - Parameters:
    ///   - transcript: 분석할 전사 엔티티
    ///   - language: 요약 및 키워드 생성에 사용할 출력 언어
    /// - Returns: 키워드 배열과 요약 엔티티의 튜플
    /// - Throws: `SummaryRepositoryError` (분석·요약 실패)
    func summarize(transcript: Transcript, language: Language) async throws(SummaryRepositoryError)
        -> (keywords: [Keyword], summary: Summary)
}
