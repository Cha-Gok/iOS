import Core
import Domain
import Foundation

#if canImport(FoundationModels)
    import FoundationModels
#endif

public actor AppleFoundationSummaryService: SummaryService {
    public init() {}

    public func summarize(text: String, language: Language) async throws(SummaryServiceError) -> (
        keywords: [String],
        summary: String
    ) {
        #if canImport(FoundationModels)
            // 취소 확인
            if Task.isCancelled { throw .cancelled }

            // 모델 사용 가능 여부 확인
            let model = SystemLanguageModel.default
            guard model.isAvailable else { throw .modelUnavailable }

            // 세션 생성
            let session = LanguageModelSession(
                model: model,
                instructions: """
                You summarize transcript text.
                Extract 3 to 5 concise keywords.
                Write a short summary in \(language.rawValue).
                Return content that matches the schema.
                """
            )

            let response: LanguageModelSession.Response<SummaryGenerationResult>

            do {
                // respond(to:generating:) 호출
                response = try await session.respond(
                    to: """
                    Read the following transcript and generate keywords and a summary.

                    Transcript:
                    \(text)
                    """,
                    generating: SummaryGenerationResult.self
                )

            } catch let error as LanguageModelSession.GenerationError {
                AppLogger.error(error)
                switch error {
                case .assetsUnavailable:
                    throw .modelUnavailable
                case .unsupportedLanguageOrLocale:
                    throw .unsupportedLanguage
                case .rateLimited:
                    throw .rateLimited
                case .decodingFailure:
                    throw .invalidResponse
                case .concurrentRequests, .exceededContextWindowSize, .guardrailViolation, .refusal, .unsupportedGuide:
                    throw .summarizeFailed
                @unknown default:
                    throw .unknown(error)
                }
            } catch {
                AppLogger.error(error)
                throw .unknown(error)
            }

            let keywords = response.content.keywords
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            let summary = response.content.summary
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !summary.isEmpty else {
                throw .invalidResponse
            }

            return (keywords, summary)
        #else
            throw .modelUnavailable
        #endif
    }
}
