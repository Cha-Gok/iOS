import Core
import Domain
import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

public struct DefaultMLXSummaryRepository: SummaryRepository {
    private let provider: any MLXModelDataSource

    public init(provider: any MLXModelDataSource) {
        self.provider = provider
    }

    public func summarize(
        transcript: Transcript,
        language: Language
    ) async throws(SummaryRepositoryError) -> (keywords: [Keyword], summary: Summary) {
        if Task.isCancelled { throw .cancelled }
        do {
            // model load
            let configuration = try matchModelConfiguration(model: ChaGokModelSupport.current.model)
            try await provider.loadModel(configuration: configuration)
            guard let container = await provider.container else { throw SummaryRepositoryError.summarizeFailed }

            // JSON 응답을 위한 스키마 강제 프롬프트 추가
            let jsonInstruction = """
            \(Policy.summaryPrompt(lang: language.rawValue))

            IMPORTANT: You must output ONLY valid JSON matching this exact schema:
            {
                "keywords": ["keyword1", "keyword2", "keyword3"],
                "keyPoints": ["point1", "point2"]
            }
            Do not include any other text or markdown tags.
            """

            let session = ChatSession(
                container,
                instructions: jsonInstruction
            )

            var summaryResponse = try await session.respond(
                to: Policy.keywordPrompt(
                    transcript: transcript.sections.map(\.text).joined(separator: "\n")
                )
            )

            if let firstOpen = summaryResponse.firstIndex(of: "{"),
               let lastClose = summaryResponse.lastIndex(of: "}")
            {
                summaryResponse = String(summaryResponse[firstOpen ... lastClose])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }

            guard let data = summaryResponse.data(using: .utf8) else {
                AppLogger.error("summaryResponse Decoding 문제: \(summaryResponse)")
                throw SummaryRepositoryError.summarizeFailed
            }

            let result = try JSONDecoder().decode(MLXSummaryResult.self, from: data)

            let keywords = result.keywords
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .map { Keyword(noteID: transcript.id, word: $0) }

            let keyPoints = result.keyPoints
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            guard !keyPoints.isEmpty else {
                throw SummaryRepositoryError.summarizeFailed
            }

            let summaryText = keyPoints.joined(separator: "\n")
            await provider.clear()
            return (keywords, Summary(text: summaryText))
        } catch {
            await provider.clear()
            AppLogger.error(error)
            if let repoError = error as? SummaryRepositoryError {
                throw repoError
            }
            throw .summarizeFailed
        }
    }

    /// Domain 객체를 통해  mlx-swift-lm의 LLMRegistry를 변환 합니다.
    private func matchModelConfiguration(model: ChaGokModel) throws(AvailableModelSupportRepositoryError)
        -> ModelConfiguration
    {
        switch model {
        case .gemma4_e2b_4bit:
            return LLMRegistry.gemma4_e2b_it_4bit
        case .none, .whisper:
            throw .notFoundModel
        }
    }
}
