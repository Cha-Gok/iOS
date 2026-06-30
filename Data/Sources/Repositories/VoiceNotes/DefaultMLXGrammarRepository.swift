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

            // 배칭을 위한 System Prompt 적용
            let session = ChatSession(container, instructions: Policy.sttBatchCorrectionPrompt)

            let sections = transcript.sections
            let totalSections = sections.count
            let batchSize = 5
            var correctedSections: [TranscriptSection] = []

            var i = 0
            while i < totalSections {
                if Task.isCancelled { break }

                // 이번 배치에 포함할 섹션들 분할 (최대 5개씩)
                let end = min(i + batchSize, totalSections)
                let batchSections = Array(sections[i ..< end])
                let batchTexts = batchSections.map(\.text)

                AppLogger.info("[\(i + 1)~\(end)/\(totalSections)] 문법 교정 배치 요청 중...")

                let prompt = Policy.batchCorrectionPrompt(texts: batchTexts)
                let response = try await session.respond(to: prompt)

                // 결과 파싱
                let correctedTexts = parseBatchResponse(
                    response,
                    batchSize: batchSections.count,
                    originalTexts: batchTexts
                )

                for (offset, section) in batchSections.enumerated() {
                    let correctedText = correctedTexts[offset]
                    AppLogger
                        .info(
                            "Section 문법 교정 완료 [\(i + offset + 1)/\(totalSections)]\n- [원본]: \(section.text)\n- [교정]: \(correctedText)"
                        )
                    correctedSections.append(TranscriptSection(timestamp: section.timestamp, text: correctedText))
                }

                let processedCount = end
                let percent = Int(Double(processedCount) / Double(totalSections) * 100.0)
                AppLogger.info("[\(processedCount)/\(totalSections) (\(percent)%)] 문법 교정 배치 완료")

                await provider.clearCache()
                i += batchSize
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

    // MARK: - Helper

    /// LLM의 배치 응답([1] 교정문장\n[2] 교정문장...)을 각 인덱스별로 견고하게 파싱합니다.
    private func parseBatchResponse(
        _ response: String,
        batchSize: Int,
        originalTexts: [String]
    ) -> [String] {
        var results = Array(repeating: "", count: batchSize)
        let lines = response.components(separatedBy: .newlines)

        // 정규식 패턴: [1] 이나 1. 또는 1: 로 시작하는 패턴 매칭
        let pattern = #"^(?:\[?(\d+)\]?[\.:\s\-]*)\s*(.*)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return originalTexts
        }

        var currentIdx: Int? = nil

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            let nsString = trimmed as NSString
            let matches = regex.matches(in: trimmed, options: [], range: NSRange(location: 0, length: nsString.length))

            if let match = matches.first, match.numberOfRanges >= 3 {
                let indexStr = nsString.substring(with: match.range(at: 1))
                let textStr = nsString.substring(with: match.range(at: 2))

                if let parsedIndex = Int(indexStr) {
                    let idx = parsedIndex - 1
                    if idx >= 0, idx < batchSize {
                        results[idx] = textStr.trimmingCharacters(in: .whitespacesAndNewlines)
                        currentIdx = idx
                    }
                }
            } else if let lastIdx = currentIdx {
                // 이전 문장의 줄바꿈 연장선인 경우
                if !results[lastIdx].isEmpty {
                    results[lastIdx] += " " + trimmed
                } else {
                    results[lastIdx] = trimmed
                }
            }
        }

        // 만약 파싱에 실패하여 빈 값이 있는 경우 원본 텍스트로 채워줍니다.
        for i in 0 ..< batchSize {
            if results[i].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                results[i] = originalTexts[i]
            }
        }

        return results
    }
}
