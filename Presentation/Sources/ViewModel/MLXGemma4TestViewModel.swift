import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import SwiftUI
import Tokenizers

@Observable
@MainActor
public final class MLXGemma4TestViewModel {
    public var status: String = "Ready"
    public var isDownloading: Bool = false
    public var isLoaded: Bool = false
    public var modelInfo: String = ""
    public var output: String = ""
    public var messages: [ChatMessage] = []

    // Summary
    public var summaryOutput: String = ""
    public var isSummarizing: Bool = false

    // Grammar Fix
    public var grammarResult: String = ""
    public var isFixingGrammar: Bool = false

    private var modelContainer: ModelContainer?

    public init() {}

    public func download() async {
        guard !isDownloading else { return }

        isDownloading = true
        status = "Downloading & Loading Model..."

        do {
            let modelConfiguration = LLMRegistry.gemma4_e2b_it_4bit

            let container = try await LLMModelFactory.shared.loadContainer(
                from: #hubDownloader(),
                using: #huggingFaceTokenizerLoader(),
                configuration: modelConfiguration
            ) { progress in
                Task { @MainActor in
                    self.status = "Downloading: \(Int(progress.fractionCompleted * 100))%"
                }
            }

            modelContainer = container
            isLoaded = true
            modelInfo = "Model Ready: \(modelConfiguration.id)"
            status = "Completed"
        } catch {
            status = "Error: \(error.localizedDescription)"
            print("Download error: \(error)")
        }

        isDownloading = false
    }

    public func generateResponse(prompt: String) async {
        guard let container = modelContainer else {
            status = "Model not loaded"
            return
        }

        let userMessage = ChatMessage(role: .user, content: prompt)
        messages.append(userMessage)

        let assistantMessage = ChatMessage(role: .assistant, content: "")
        messages.append(assistantMessage)
        let assistantIndex = messages.count - 1

        status = "Generating..."
        output = ""

        do {
            let session = ChatSession(container)
            let response = try await session.respond(to: prompt)

            messages[assistantIndex].content = response
            output = response
            status = "Finished"
        } catch {
            status = "Generation Error: \(error.localizedDescription)"
        }
    }

    public func summarize(text: String) async {
        let prompt = "Summarize the following text briefly:\n\n\(text)"
        await generateResponse(prompt: prompt)
    }

    public func summarizeToThreeLines(text: String) async {
        isSummarizing = true
        summaryOutput = ""

        guard let container = modelContainer else {
            summaryOutput = "Model not loaded"
            isSummarizing = false
            return
        }

        let prompt = "다음 텍스트를 정확히 3줄로 요약해주세요. 각 줄은 핵심 내용을 담아야 합니다:\n\n\(text)"

        do {
            let session = ChatSession(container)
            summaryOutput = try await session.respond(to: prompt)
        } catch {
            summaryOutput = "Error: \(error.localizedDescription)"
        }

        isSummarizing = false
    }

    public func fixGrammar(text: String) async {
        isFixingGrammar = true
        grammarResult = ""

        guard let container = modelContainer else {
            grammarResult = "Model not loaded"
            isFixingGrammar = false
            return
        }

        let prompt = "한국어로 변환 후 다음 문장의 문법을 교정하고 자연스럽게 다듬어주세요. 다른 설명 없이 교정된 문장만 출력하세요:\n\n\(text)"

        do {
            let session = ChatSession(container)
            grammarResult = try await session.respond(to: prompt)
        } catch {
            grammarResult = "Error: \(error.localizedDescription)"
        }

        isFixingGrammar = false
    }
}

public struct ChatMessage: Identifiable, Equatable {
    public let id = UUID()
    public let role: ChatRole
    public var content: String
}

public enum ChatRole {
    case user
    case assistant
}
