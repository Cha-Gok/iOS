import Foundation

/// 문법 교정(Grammar)을 담당하는 리포지토리 프로토콜.
public protocol GrammarRepository: Sendable {
    /// 전사 텍스트의 문법, 철자, 구두점을 교정합니다.
    /// - Parameters:
    ///   - transcript: 교정할 전사 엔티티
    /// - Returns: 문법이 교정된 새로운 전사 엔티티
    /// - Throws: `GrammarRepositoryError` (문법 교정 실패)
    func correct(transcript: Transcript) async throws(GrammarRepositoryError) -> Transcript
}
