import Foundation

/// 요약(Summary) 및 분석을 담당하는 리포지토리 프로토콜.
public protocol SummaryRepository: Sendable {
    /// 전사 텍스트를 분석하여 키워드와 요약을 생성합니다.
    /// - Parameter transcript: 분석할 전사 엔티티
    /// - Returns: 키워드 배열과 요약 엔티티의 튜플
    /// - Throws: `SummaryRepositoryError` (분석·요약 실패)
    func summarize(transcript: Transcript) async throws(SummaryRepositoryError)
        -> (keywords: [Keyword], summary: Summary)
}
