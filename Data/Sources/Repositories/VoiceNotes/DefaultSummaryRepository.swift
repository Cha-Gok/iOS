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
                instructions: Policy.summaryPrompt(lang: language.rawValue)
            )

            do {
                let response = try await session.respond(
                    to: Policy.keywordPrompt(
                        transcript: transcript.sections.map(\.text).joined(separator: "\n")
                    ),
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
