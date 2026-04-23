import Core
import Domain
import Foundation
#if canImport(FoundationModels)
    import FoundationModels
#endif

/// 요약(Summary) 리포지토리 기본 구현체.
public struct DefaultSummaryRepository: SummaryRepository {
    public init() {}

    public func summarize(transcript: Domain.Transcript, language: Domain.Language) async throws(SummaryRepositoryError)
        -> (keywords: [Domain.Keyword], summary: Domain.Summary)
    {
        #if canImport(FoundationModels)
            if Task.isCancelled { throw .cancelled }

            let model = SystemLanguageModel.default
            guard model.isAvailable else { throw .summarizeFailed }

            let session = LanguageModelSession(
                model: model,
                instructions: """
                You summarize transcript text.
                Extract 3 to 5 concise keywords.
                Write 1 to 3 concise key points in \(language.rawValue) that capture the main ideas.
                Use fewer key points for short or single-topic transcripts, and more for longer or multi-topic ones.
                Each key point should be a single standalone sentence without bullet markers or numbering.
                Return content that matches the schema.
                """
            )

            do {
                let response = try await session.respond(
                    to: """
                    Read the following transcript and generate keywords and key points.

                    Transcript:
                    \(transcript.sections.map(\.text).joined(separator: "\n"))
                    """,
                    generating: SummaryGenerationResult.self
                )

                let keywords = response.content.keywords
                    .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .map { Keyword(noteID: transcript.id, word: $0) }

                let keyPoints = response.content.keyPoints
                    .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }

                guard !keyPoints.isEmpty else {
                    throw SummaryRepositoryError.summarizeFailed
                }

                let summaryText = keyPoints.joined(separator: "\n")

                return (keywords, Summary(text: summaryText))

            } catch let error as LanguageModelSession.GenerationError {
                AppLogger.error(error)
                throw .summarizeFailed
            } catch {
                AppLogger.error(error)
                if let repoError = error as? SummaryRepositoryError {
                    throw repoError
                }
                throw .unknown(error)
            }
        #else
            throw .summarizeFailed
        #endif
    }
}
