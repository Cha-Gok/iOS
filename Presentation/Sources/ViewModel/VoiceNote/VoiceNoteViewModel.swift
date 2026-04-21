import Core
import Domain
import Foundation

public protocol VoiceNoteCoordinatorDelegate: BaseCoordinatorDelegate {}

@MainActor
@Observable
public final class VoiceNoteViewModel {
    public private(set) var voiceNote: VoiceNote
    public private(set) var folderName: String = ""
    public private(set) var errorMessage: String?
    public private(set) var editingMode: EditingMode?
    public private(set) var currentPlaybackState = AudioPlaybackState(status: .idle, currentTime: 0, duration: 0)
    public private(set) var playingSectionIndex: Int?
    public private(set) var editableScriptSections: [TranscriptSection] = []
    public private(set) var currentPage: Page = .summary

    @ObservationIgnored
    private var playbackObservationTask: Task<Void, Never>?
    @ObservationIgnored
    private var voiceNoteObservationTask: Task<Void, Never>?
    @ObservationIgnored
    private var wasPlayingBeforeSeek = false
    public weak var coordinator: VoiceNoteCoordinatorDelegate?

    // MARK: - UseCases

    private let voiceNoteUseCase: any VoiceNoteUseCase
    private let folderUseCase: any FolderUseCase
    private let playbackRepository: any VoiceRecordPlaybackRepository
    private let wasteBasketRepository: any WasteBasketRepository

    // MARK: - Init

    public init(
        voiceNote: VoiceNote,
        voiceNoteUseCase: any VoiceNoteUseCase,
        folderUseCase: any FolderUseCase,
        playbackRepository: any VoiceRecordPlaybackRepository,
        wasteBasketRepository: any WasteBasketRepository
    ) {
        self.voiceNote = voiceNote
        self.voiceNoteUseCase = voiceNoteUseCase
        self.folderUseCase = folderUseCase
        self.playbackRepository = playbackRepository
        self.wasteBasketRepository = wasteBasketRepository
    }

    deinit {
        playbackObservationTask?.cancel()
        voiceNoteObservationTask?.cancel()
    }

    // MARK: - View Actions

    public func onAppear() {
        setupPlayback()
        fetchFolderName()
        observeVoiceNote()
    }

    public func onDisappear() {
        stop()
    }

    public func playPause() {
        if currentPlaybackState.status == .playing {
            pause()
        } else {
            play()
        }
    }

    public func rewind() {
        seek(to: currentPlaybackState.currentTime - Policy.playbackSkipInterval)
    }

    public func forward() {
        seek(to: currentPlaybackState.currentTime + Policy.playbackSkipInterval)
    }

    public func seekBegan() {
        wasPlayingBeforeSeek = currentPlaybackState.status == .playing
        if wasPlayingBeforeSeek { pause() }
    }

    public func seekEnded(_ time: TimeInterval) {
        seek(to: time)
        if wasPlayingBeforeSeek {
            wasPlayingBeforeSeek = false
            play()
        }
    }

    public func scriptTimestampTapped(_ time: TimeInterval) {
        seek(to: time)
        play()
    }

    public func pop() {
        coordinator?.pop()
    }

    public func moveVoiceNote() {
        coordinator?.presentFolderList(with: .single(voiceNote))
    }

    public func enterTitleEditing() {
        editingMode = .title
    }

    public func enterScriptEditing() {
        if currentPlaybackState.status == .playing { pause() }
        editableScriptSections = scriptSections
        currentPage = .script
        editingMode = .script
    }

    public func cancelEditing() {
        editingMode = nil
    }

    public func updateCurrentPage(_ page: Page) {
        currentPage = page
    }

    public func updateScriptSection(sectionIndex: Int, text: String) {
        guard sectionIndex < editableScriptSections.count else { return }
        var sections = editableScriptSections
        sections[sectionIndex] = TranscriptSection(
            timestamp: sections[sectionIndex].timestamp,
            text: text
        )
        editableScriptSections = sections
    }

    public func doneTitleEditing(title: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty, trimmedTitle != voiceNote.title else {
            editingMode = nil
            return
        }

        let updatedNote = VoiceNote(
            id: voiceNote.id,
            title: trimmedTitle,
            createdAt: voiceNote.createdAt,
            updatedAt: .now,
            folderID: voiceNote.folderID,
            voiceRecord: voiceNote.voiceRecord,
            keywords: voiceNote.keywords,
            transcript: voiceNote.transcript,
            summary: voiceNote.summary,
            analysisState: voiceNote.analysisState
        )

        do {
            _ = try voiceNoteUseCase.update(updatedNote)
            voiceNote = updatedNote
            editingMode = nil
        } catch {
            errorMessage = "제목 수정에 실패했습니다: \(error.localizedDescription)"
        }
    }

    public func doneScriptEditing() {
        guard let updatedTranscript = makeUpdatedTranscript() else {
            editingMode = nil
            return
        }

        let updatedNote = VoiceNote(
            id: voiceNote.id,
            title: voiceNote.title,
            createdAt: voiceNote.createdAt,
            updatedAt: .now,
            folderID: voiceNote.folderID,
            voiceRecord: voiceNote.voiceRecord,
            keywords: voiceNote.keywords,
            transcript: updatedTranscript,
            summary: voiceNote.summary,
            analysisState: voiceNote.analysisState
        )

        do {
            _ = try voiceNoteUseCase.update(updatedNote)
            voiceNote = updatedNote
            editingMode = nil
        } catch {
            errorMessage = "스크립트 수정에 실패했습니다: \(error.localizedDescription)"
        }
    }

    private func makeUpdatedTranscript() -> Transcript? {
        guard let original = voiceNote.transcript else { return nil }

        let sections = editableScriptSections.filter {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        return Transcript(
            id: original.id,
            createdAt: original.createdAt,
            updatedAt: .now,
            sections: sections
        )
    }

    public func deleteVoiceNote() {
        moveToWasteBasket()
    }

    public func regenerateSummary() {
        voiceNoteUseCase.regenerateSummary(id: voiceNote.id)
    }

    public func dismissError() {
        errorMessage = nil
    }

    // MARK: - Private Methods

    private func fetchFolderName() {
        do {
            folderName = try folderUseCase.fetch(by: voiceNote.folderID).name
        } catch {
            AppLogger.error(error)
        }
    }

    private func setupPlayback() {
        playbackObservationTask?.cancel()
        playbackObservationTask = nil
        do {
            let stream = try playbackRepository.prepare(
                audioFilePath: voiceNote.voiceRecord.audioFilePath
            )
            playbackObservationTask = Task {
                for await playbackState in stream {
                    currentPlaybackState = playbackState
                    updatePlayingParagraph()
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func observeVoiceNote() {
        voiceNoteObservationTask?.cancel()
        voiceNoteObservationTask = Task {
            do {
                let stream = try voiceNoteUseCase.observe(id: voiceNote.id)
                for await note in stream.dropFirst() {
                    let folderChanged = voiceNote.folderID != note.folderID
                    voiceNote = note
                    if folderChanged { fetchFolderName() }
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func stop() {
        playbackObservationTask?.cancel()
        playbackObservationTask = nil
        voiceNoteObservationTask?.cancel()
        voiceNoteObservationTask = nil
        do {
            try playbackRepository.stop()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func play() {
        do {
            try playbackRepository.play()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func pause() {
        do {
            try playbackRepository.pause()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func seek(to time: TimeInterval) {
        do {
            try playbackRepository.seek(to: time)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func moveToWasteBasket() {
        do {
            stop()
            try wasteBasketRepository.moveToWasteBasket(item: .voiceNote(obj: voiceNote))
            coordinator?.pop()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updatePlayingParagraph() {
        let currentTime = currentPlaybackState.currentTime
        let sections = scriptSections
        guard !sections.isEmpty else {
            guard playingSectionIndex != nil else { return }
            playingSectionIndex = nil
            return
        }

        var newIndex: Int?
        for (index, section) in sections.enumerated().reversed() where section.timestamp <= currentTime {
            newIndex = index
            break
        }
        guard playingSectionIndex != newIndex else { return }
        playingSectionIndex = newIndex
    }
}

// MARK: - Computed Properties

public extension VoiceNoteViewModel {
    var title: String {
        voiceNote.title
    }

    var metadataText1: String {
        let created = voiceNote.createdAt.toString(format: "yyyy.MM.dd · a HH:mm")
        guard voiceNote.createdAt != voiceNote.updatedAt else { return created }
        let updated = voiceNote.updatedAt.toString(format: "yyyy.MM.dd")
        return "\(created) (\(updated) 수정됨)"
    }

    var metadataText2: String {
        voiceNote.voiceRecord.duration.koreanDurationString
    }

    var keywords: [String] {
        voiceNote.keywords.map(\.word).sorted()
    }

    var keyPoints: [KeyPoint] {
        guard let summary = voiceNote.summary else { return [] }
        return summary.text
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .enumerated()
            .map { KeyPoint(number: $0.offset + 1, text: $0.element) }
    }

    var scriptSections: [TranscriptSection] {
        if editingMode == .script { return editableScriptSections }
        return voiceNote.transcript?.sections ?? []
    }

    var hasScriptEdits: Bool {
        editableScriptSections != (voiceNote.transcript?.sections ?? [])
    }

    /// 요약 생성 이후 스크립트가 수정되어 요약이 최신 상태가 아닌지 여부.
    var isSummaryOutdated: Bool {
        guard let summary = voiceNote.summary,
              let transcript = voiceNote.transcript else { return false }
        return summary.createdAt < transcript.updatedAt
    }
}

// MARK: - Nested Types

public extension VoiceNoteViewModel {
    enum EditingMode: Sendable {
        case title
        case script
    }

    enum Page: Int, CaseIterable, Sendable {
        case summary
        case script

        public var title: String {
            switch self {
            case .summary: return "요약"
            case .script: return "스크립트"
            }
        }
    }
}
