import Core
import Domain
import Foundation

/// 요약(Summary) 리포지토리 기본 구현체.
public struct DefaultSummaryRepository: SummaryRepository {
    private let service: any SummaryService

    public init(service: any SummaryService) {
        self.service = service
    }

    public func summarize(transcript: Transcript, language: Language) async throws(SummaryRepositoryError)
        -> (keywords: [Keyword], summary: Summary)
    {
        if Task.isCancelled { throw .cancelled }

        do {
            let (keywords, summaryText) = try await service.summarize(text: transcript.text, language: language)

            // Domain 엔티티로 변환
            let keywordEntities = keywords.map { Keyword(noteId: transcript.id, word: $0) }
            let summaryEntity = Summary(text: summaryText)

            return (keywordEntities, summaryEntity)
        } catch {
            AppLogger.error(error)
            throw SummaryRepositoryError(error)
        }
    }
}
