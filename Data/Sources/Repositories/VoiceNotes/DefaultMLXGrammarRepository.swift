import Core
import Domain
import Foundation
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

public struct DefaultMLXGrammarRepository: GrammarRepository {
    private let provider: any MLXModelDataSource

    public init(provider: any MLXModelDataSource) {
        self.provider = provider
    }

    public func correct(transcript: Transcript) async throws(GrammarRepositoryError) -> Transcript {
        if Task.isCancelled { throw .cancelled }
        AppLogger.info("문법 교정 시작 (ID: \(transcript.id))")
        do {
            // MLX 모델 로드
            let context: ModelContext = try await provider.loadModel()
            let container: ModelContainer = ModelContainer(context: context)
            let session = ChatSession(container, instructions: Policy.sttCorrectionPrompt)

            var correctedSections: [TranscriptSection] = []
            for section in transcript.sections {
                if Task.isCancelled { break }
                let response = try await session.respond(to: Policy.correctionPrompt(text: section.text))
                let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
                correctedSections.append(TranscriptSection(timestamp: section.timestamp, text: trimmed))
                await provider.clearCache()
            }

            if Task.isCancelled {
                await provider.clear()
                throw GrammarRepositoryError.cancelled
            }

            await provider.clearCache()

            AppLogger.info("문법 교정 종료 (ID: \(transcript.id))")
            return Transcript(
                id: transcript.id,
                createdAt: transcript.createdAt,
                updatedAt: Date.now,
                sections: correctedSections
            )
        } catch {
            await provider.clear()
            AppLogger.error(error)
            if let repoError = error as? GrammarRepositoryError {
                throw repoError
            }
            throw .correctionFailed
        }
    }
}
