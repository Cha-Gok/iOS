import Domain
import Foundation

public struct KeyPoint {
    let number: Int
    let text: String
}

public struct ScriptSection {
    let timestamp: String
    let paragraphs: [String]
}

@MainActor
@Observable
public final class VoiceNoteViewModel {
    // MARK: - Analysis State

    public enum AnalysisState {
        case analyzing
        case completed
        case failed
    }

    public private(set) var analysisState: AnalysisState = .analyzing
    public private(set) var errorMessage: String?

    // MARK: - Data

    private var voiceNote: VoiceNote

    // MARK: - Mapped Properties

    public var title: String {
        voiceNote.title
    }

    public var folderName: String = ""

    public var metadataText1: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd · a HH:mm"
        let created = formatter.string(from: voiceNote.createdAt)
        guard voiceNote.createdAt != voiceNote.updatedAt else { return created }
        let updatedFormatter = DateFormatter()
        updatedFormatter.locale = Locale(identifier: "ko_KR")
        updatedFormatter.dateFormat = "yyyy.MM.dd"
        return "\(created) (\(updatedFormatter.string(from: voiceNote.updatedAt)) 수정됨)"
    }

    public var metadataText2: String {
        let total = Int(voiceNote.voiceRecord.duration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 { return "\(hours)시간 \(minutes)분 \(seconds)초" }
        if minutes > 0 { return "\(minutes)분 \(seconds)초" }
        return "\(seconds)초"
    }

    public var keywords: [String] {
        voiceNote.keywords.map(\.word)
    }

    public var keyPoints: [KeyPoint] {
        guard let summary = voiceNote.summary else { return [] }
        return summary.text
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .enumerated()
            .map { KeyPoint(number: $0.offset + 1, text: $0.element) }
    }

    public var scriptSections: [ScriptSection] {
        guard let transcript = voiceNote.transcript else { return [] }
        let paragraphs = transcript.text
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return [ScriptSection(timestamp: "00:00", paragraphs: paragraphs)]
    }

    // MARK: - UseCases

    private let audioToSummaryUseCase: any AudioToSummaryUseCase
    private let updateVoiceNoteUseCase: any UpdateVoiceNoteUseCase
    private let fetchLanguageUseCase: any FetchLanguageUseCase
    private let fetchFolderUseCase: any ReadFolderUseCase

    // MARK: - Init

    public init(
        voiceNote: VoiceNote,
        audioToSummaryUseCase: any AudioToSummaryUseCase,
        updateVoiceNoteUseCase: any UpdateVoiceNoteUseCase,
        fetchLanguageUseCase: any FetchLanguageUseCase,
        fetchFolderUseCase: any ReadFolderUseCase
    ) {
        self.voiceNote = voiceNote
        self.audioToSummaryUseCase = audioToSummaryUseCase
        self.updateVoiceNoteUseCase = updateVoiceNoteUseCase
        self.fetchLanguageUseCase = fetchLanguageUseCase
        self.fetchFolderUseCase = fetchFolderUseCase
    }

    // MARK: - Analysis

    public func startAnalysis() {
        Task { [self] in
            await loadFolderName()
            do {
                let language = try await fetchLanguageUseCase.execute()
                let result = try await audioToSummaryUseCase.execute(
                    audioFileURL: voiceNote.voiceRecord.audioFilePath,
                    language: language
                )
                let updated = VoiceNote(
                    id: voiceNote.id,
                    title: voiceNote.title,
                    createdAt: voiceNote.createdAt,
                    updatedAt: .now,
                    folderID: voiceNote.folderID,
                    voiceRecord: voiceNote.voiceRecord,
                    keywords: result.keywords,
                    transcript: result.transcript,
                    summary: result.summary
                )
                voiceNote = try await updateVoiceNoteUseCase.execute(updated)
                analysisState = .completed
            } catch {
                errorMessage = error.localizedDescription
                analysisState = .failed
            }
        }
    }

    private func loadFolderName() async {
        guard folderName.isEmpty else { return }

        do {
            let folders = try await fetchFolderUseCase.execute()
            folderName = folders.first(where: { $0.id == voiceNote.folderID })?.name ?? ""
        } catch {
            folderName = ""
        }
    }
}
