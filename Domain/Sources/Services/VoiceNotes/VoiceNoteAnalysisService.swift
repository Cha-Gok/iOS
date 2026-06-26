import Core
import Foundation

/// 음성 메모의 전사 → 요약 파이프라인 실행을 오케스트레이션하는 도메인 서비스.
///
/// 진행 중 Task 핸들과 이전 상태(previousState)를 메모리에 보관하며,
/// 취소/앱 종료 시 DB 상태를 이전 상태로 되돌린다.
/// 뷰 생명주기와 독립적으로 동작한다.
///
/// - TODO: 크래시 등으로 `applicationWillTerminate`가 호출되지 못한 경우
///   DB에 `.transcribing` / `.summarizing` / `.regenerating` 상태가 잔존할 수 있다.
///   앱 재기동 시 stuck 상태를 스캔해 합리적 상태로 revert 하는 정책 필요.
@MainActor
public protocol VoiceNoteAnalysisService: Sendable {
    /// 현재 `analysisState`에 따라 전사 또는 요약을 큐잉한다.
    /// 이미 진행 중인 노트면 no-op.
    func enqueue(voiceNoteID: UUID)

    /// 완료/실패 상태의 요약을 재생성한다.
    func regenerate(voiceNoteID: UUID)

    /// 특정 노트의 분석을 취소하고 전이 상태라면 이전 상태로 되돌린다.
    func cancel(voiceNoteID: UUID)

    /// 진행 중인 모든 분석을 취소하고 전이 상태라면 이전 상태로 되돌린다.
    func cancelAll()
}

public final class DefaultVoiceNoteAnalysisService: VoiceNoteAnalysisService {
    private struct Entry {
        let task: Task<Void, Never>
        let previousState: AnalysisState
    }

    private var entries: [UUID: Entry] = [:]
    private let voiceNoteRepository: any VoiceNoteRepository
    private let sttRepository: any STTRepository
    private let summaryRepository: any SummaryRepository
    private let languageRepository: any LanguageRepository
    private let grammarRepository: any GrammarRepository

    public init(
        voiceNoteRepository: any VoiceNoteRepository,
        sttRepository: any STTRepository,
        summaryRepository: any SummaryRepository,
        languageRepository: any LanguageRepository,
        grammarRepository: any GrammarRepository
    ) {
        self.voiceNoteRepository = voiceNoteRepository
        self.sttRepository = sttRepository
        self.summaryRepository = summaryRepository
        self.languageRepository = languageRepository
        self.grammarRepository = grammarRepository
    }

    // MARK: - Public API

    public func enqueue(voiceNoteID: UUID) {
        guard entries[voiceNoteID] == nil else { return }
        guard let voiceNote = fetch(voiceNoteID) else { return }

        switch voiceNote.analysisState {
        case .pending:
            startTranscription(for: voiceNote, previousState: .pending)
        case .transcribed:
            // 문법 교정과 요약을 동일 파이프라인으로 수행합니다.
            startGrammarCheckAndSummarization(for: voiceNote, previousState: .transcribed)
        case .transcribing, .transcriptionFailed, .summarizing, .regenerating,
             .completed, .summarizationFailed, .grammarChecked, .grammarChecking, .grammarCheckFailed:
            break
        }
    }

    public func regenerate(voiceNoteID: UUID) {
        guard entries[voiceNoteID] == nil else { return }
        guard let voiceNote = fetch(voiceNoteID), voiceNote.transcript != nil else { return }

        switch voiceNote.analysisState {
        case .completed, .summarizationFailed:
            startSummarization(
                for: voiceNote,
                previousState: voiceNote.analysisState,
                transientState: .regenerating
            )
        case .pending, .transcribing, .transcriptionFailed, .transcribed,
             .summarizing, .regenerating, .grammarChecked, .grammarChecking, .grammarCheckFailed:
            break
        }
    }

    public func cancel(voiceNoteID: UUID) {
        guard let entry = entries.removeValue(forKey: voiceNoteID) else { return }
        entry.task.cancel()
        revertState(voiceNoteID: voiceNoteID, to: entry.previousState)
    }

    public func cancelAll() {
        let snapshot = entries
        entries.removeAll()
        for (id, entry) in snapshot {
            entry.task.cancel()
            revertState(voiceNoteID: id, to: entry.previousState)
        }
    }

    // MARK: - Pipeline

    private func startTranscription(for voiceNote: VoiceNote, previousState: AnalysisState) {
        persist(voiceNote: voiceNote, analysisState: .transcribing)
        let task = Task { [weak self] in
            guard let self else { return }
            do {
                let transcript = try await sttRepository.transcribe(
                    audioFilePath: voiceNote.voiceRecord.audioFilePath
                )
                if Task.isCancelled { return }
                let withTranscript = makeUpdated(
                    from: voiceNote,
                    transcript: transcript,
                    analysisState: .transcribed
                )
                persist(voiceNote: withTranscript)
                if Task.isCancelled { return }
                entries.removeValue(forKey: voiceNote.id)
                startGrammarCheckAndSummarization(for: withTranscript, previousState: .transcribed)
            } catch {
                AppLogger.error(error)
                if !Task.isCancelled {
                    persist(voiceNote: voiceNote, analysisState: .transcriptionFailed)
                }
                entries.removeValue(forKey: voiceNote.id)
            }
        }
        entries[voiceNote.id] = Entry(task: task, previousState: previousState)
    }

    private func startGrammarCheckAndSummarization(for voiceNote: VoiceNote, previousState: AnalysisState) {
        guard let transcript = voiceNote.transcript else { return }
        persist(voiceNote: voiceNote, analysisState: .grammarChecking)

        let task = Task { [weak self] in
            guard let self else { return }
            do {
                // 1. 문법 교정 실행
                let correctedTranscript = try await self.grammarRepository.correct(transcript: transcript)
                if Task.isCancelled { return }

                let withGrammar = self.makeUpdated(
                    from: voiceNote,
                    transcript: correctedTranscript,
                    analysisState: .grammarChecked
                )
                persist(voiceNote: withGrammar)

                // 2. 요약 실행
                persist(voiceNote: withGrammar, analysisState: .summarizing)
                let language = self.languageRepository.fetchLanguage()
                let (keywords, summary) = try await self.summaryRepository.summarize(
                    transcript: correctedTranscript,
                    language: language
                )
                if Task.isCancelled { return }

                let completed = self.makeUpdated(
                    from: withGrammar,
                    keywords: keywords,
                    summary: summary,
                    analysisState: .completed
                )
                persist(voiceNote: completed)
            } catch {
                AppLogger.error(error)
                if !Task.isCancelled {
                    persist(voiceNote: voiceNote, analysisState: .summarizationFailed)
                }
            }
            entries.removeValue(forKey: voiceNote.id)
        }
        entries[voiceNote.id] = Entry(task: task, previousState: previousState)
    }

    private func startSummarization(
        for voiceNote: VoiceNote,
        previousState: AnalysisState,
        transientState: AnalysisState = .summarizing
    ) {
        guard let transcript = voiceNote.transcript else { return }
        persist(voiceNote: voiceNote, analysisState: transientState)
        let task = Task { [weak self] in
            guard let self else { return }
            do {
                let language = languageRepository.fetchLanguage()
                let (keywords, summary) = try await summaryRepository.summarize(
                    transcript: transcript,
                    language: language
                )
                if Task.isCancelled { return }
                let completed = makeUpdated(
                    from: voiceNote,
                    keywords: keywords,
                    summary: summary,
                    analysisState: .completed
                )
                persist(voiceNote: completed)
            } catch {
                AppLogger.error(error)
                if !Task.isCancelled {
                    persist(voiceNote: voiceNote, analysisState: .summarizationFailed)
                }
            }
            entries.removeValue(forKey: voiceNote.id)
        }
        entries[voiceNote.id] = Entry(task: task, previousState: previousState)
    }

    // MARK: - Storage Helpers

    private func fetch(_ id: UUID) -> VoiceNote? {
        do {
            return try voiceNoteRepository.fetch(byId: id)
        } catch {
            AppLogger.error(error)
            return nil
        }
    }

    private func persist(voiceNote: VoiceNote) {
        do {
            _ = try voiceNoteRepository.update(voiceNote)
        } catch {
            AppLogger.error(error)
        }
    }

    private func persist(voiceNote: VoiceNote, analysisState: AnalysisState) {
        let updated = makeUpdated(from: voiceNote, analysisState: analysisState)
        persist(voiceNote: updated)
    }

    private func revertState(voiceNoteID: UUID, to previousState: AnalysisState) {
        guard let current = fetch(voiceNoteID) else { return }
        switch current.analysisState {
        case .transcribing, .summarizing, .regenerating:
            persist(voiceNote: current, analysisState: previousState)
        default:
            break
        }
    }

    private func makeUpdated(
        from voiceNote: VoiceNote,
        transcript: Transcript? = nil,
        keywords: [Keyword]? = nil,
        summary: Summary? = nil,
        analysisState: AnalysisState
    ) -> VoiceNote {
        VoiceNote(
            id: voiceNote.id,
            title: voiceNote.title,
            createdAt: voiceNote.createdAt,
            updatedAt: voiceNote.updatedAt,
            folderID: voiceNote.folderID,
            voiceRecord: voiceNote.voiceRecord,
            keywords: keywords ?? voiceNote.keywords,
            transcript: transcript ?? voiceNote.transcript,
            summary: summary ?? voiceNote.summary,
            deletedAt: voiceNote.deletedAt,
            analysisState: analysisState
        )
    }
}


