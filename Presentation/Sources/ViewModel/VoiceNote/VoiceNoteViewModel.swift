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
    private let languageRepository: any LanguageRepository
    private let playbackRepository: any VoiceRecordPlaybackRepository
    private let wasteBasketRepository: any WasteBasketRepository

    // MARK: - Init

    public init(
        voiceNote: VoiceNote,
        voiceNoteUseCase: any VoiceNoteUseCase,
        folderUseCase: any FolderUseCase,
        languageRepository: any LanguageRepository,
        playbackRepository: any VoiceRecordPlaybackRepository,
        wasteBasketRepository: any WasteBasketRepository
    ) {
        self.voiceNote = voiceNote
        self.voiceNoteUseCase = voiceNoteUseCase
        self.folderUseCase = folderUseCase
        self.languageRepository = languageRepository
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
        switch voiceNote.analysisState {
        case .pending, .failed:
            voiceNote.analysisState = .analyzing
            Task { await performTranscription() }
        case .transcribed:
            voiceNote.analysisState = .analyzing
            Task { await performSummarization() }
        case .analyzing, .completed:
            break
        }
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
        editingMode = .script
    }

    public func cancelEditing() {
        editingMode = nil
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
            sections: sections
        )
    }

    public func deleteVoiceNote() {
        moveToWasteBasket()
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

    private func performTranscription() async {
        do {
            let transcript = try await voiceNoteUseCase.transcribe(
                audioFilePath: voiceNote.voiceRecord.audioFilePath
            )
            let withTranscript = VoiceNote(
                id: voiceNote.id,
                title: voiceNote.title,
                createdAt: voiceNote.createdAt,
                updatedAt: .now,
                folderID: voiceNote.folderID,
                voiceRecord: voiceNote.voiceRecord,
                transcript: transcript,
                analysisState: .transcribed
            )
            _ = try voiceNoteUseCase.update(withTranscript)
            await performSummarization()
        } catch {
            errorMessage = error.localizedDescription
            voiceNote.analysisState = .failed
        }
    }

    private func performSummarization() async {
        guard let transcript = voiceNote.transcript else { return }
        do {
            let language = languageRepository.fetchLanguage()
            let (keywords, summary) = try await voiceNoteUseCase.summarize(
                transcript: transcript,
                language: language
            )
            let completed = VoiceNote(
                id: voiceNote.id,
                title: voiceNote.title,
                createdAt: voiceNote.createdAt,
                updatedAt: .now,
                folderID: voiceNote.folderID,
                voiceRecord: voiceNote.voiceRecord,
                keywords: keywords,
                transcript: transcript,
                summary: summary,
                analysisState: .completed
            )
            _ = try voiceNoteUseCase.update(completed)
        } catch {
            // STT는 성공했으므로 .failed로 덮어쓰지 않음 — 스크립트는 유지
            errorMessage = error.localizedDescription
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
}

// MARK: - Nested Types

public extension VoiceNoteViewModel {
    enum EditingMode: Sendable {
        case title
        case script
    }
}

#if DEBUG
    extension VoiceNoteViewModel {
        static func preview() -> VoiceNoteViewModel {
            let noteID = UUID()
            let voiceNote = VoiceNote(
                id: noteID,
                title: "미리보기 회의록",
                createdAt: Date.now.addingTimeInterval(-3600),
                updatedAt: Date.now.addingTimeInterval(-1800),
                folderID: UUID(),
                voiceRecord: VoiceRecord(audioFilePath: "preview.m4a", duration: 245),
                keywords: [
                    Keyword(noteID: noteID, word: "디자인"),
                    Keyword(noteID: noteID, word: "회의"),
                    Keyword(noteID: noteID, word: "마감"),
                    Keyword(noteID: noteID, word: "일정")
                ],
                transcript: Transcript(sections: [
                    TranscriptSection(
                        timestamp: 0,
                        text: "오늘 회의는 다음 주 디자인 마감 일정을 정리하는 자리였습니다."
                    ),
                    TranscriptSection(
                        timestamp: 45,
                        text: "주요 컴포넌트 세 가지를 먼저 마무리하기로 했고, 나머지 항목은 추후 논의합니다."
                    ),
                    TranscriptSection(
                        timestamp: 120,
                        text: "다음 미팅은 수요일 오후로 예정되어 있습니다."
                    )
                ]),
                summary: Summary(
                    text: "다음 주 디자인 마감 일정 확정\n주요 컴포넌트 세 가지 우선 처리\n수요일 오후 추가 미팅"
                ),
                analysisState: .completed
            )
            return VoiceNoteViewModel(
                voiceNote: voiceNote,
                voiceNoteUseCase: PreviewVoiceNoteUseCase(items: [voiceNote]),
                folderUseCase: PreviewFolderUseCase(),
                languageRepository: PreviewLanguageRepository(),
                playbackRepository: PreviewPlaybackRepository(),
                wasteBasketRepository: PreviewWasteBasketRepository()
            )
        }
    }

    private struct PreviewVoiceNoteUseCase: VoiceNoteUseCase {
        let items: [VoiceNote]

        func create(_ voiceRecord: VoiceRecord) throws(VoiceNoteUseCaseError) -> VoiceNote {
            VoiceNote(
                title: "미리보기 기록",
                folderID: UUID(),
                voiceRecord: voiceRecord
            )
        }

        func fetchAllFromDefaultFolder() throws(VoiceNoteUseCaseError) -> [VoiceNote] {
            items
        }

        func fetchAll(folderID _: UUID) throws(VoiceNoteUseCaseError) -> [VoiceNote] {
            items
        }

        func fetch(byId id: UUID) throws(VoiceNoteUseCaseError) -> VoiceNote {
            guard let item = items.first(where: { $0.id == id }) else { throw .recordNotFound(id) }
            return item
        }

        func fetchRecent(limit: Int) throws(VoiceNoteUseCaseError) -> [VoiceNote] {
            Array(items.prefix(limit))
        }

        func update(_ voiceNote: VoiceNote) throws(VoiceNoteUseCaseError) -> VoiceNote {
            voiceNote
        }

        func transcribe(audioFilePath _: String) async throws(VoiceNoteUseCaseError) -> Transcript {
            Transcript()
        }

        func summarize(
            transcript _: Transcript,
            language _: Language
        ) async throws(VoiceNoteUseCaseError) -> (keywords: [Keyword], summary: Summary) {
            (keywords: [], summary: Summary(text: ""))
        }

        func observe(id: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<VoiceNote> {
            guard let item = items.first(where: { $0.id == id }) else { throw .recordNotFound(id) }
            return AsyncStream { continuation in
                continuation.yield(item)
                continuation.finish()
            }
        }
    }

    private struct PreviewFolderUseCase: FolderUseCase {
        func create(name: String) throws(FolderUseCaseError) -> Folder {
            Folder(name: name, isDeletable: true)
        }

        func createDefault() throws(FolderUseCaseError) -> Folder {
            Folder(name: "기본 폴더", isDeletable: false)
        }

        func fetchAll() throws(FolderUseCaseError) -> [Folder] {
            [Folder(name: "기본 폴더", isDeletable: false)]
        }

        func fetchDeletableFolders() throws(FolderUseCaseError) -> [Folder] {
            []
        }

        func fetch(by _: UUID) throws(FolderUseCaseError) -> Folder {
            Folder(name: "기본 폴더", isDeletable: false)
        }

        func update(_ folder: Folder) throws(FolderUseCaseError) -> Folder {
            folder
        }
    }

    private struct PreviewLanguageRepository: LanguageRepository {
        func fetchLanguage() -> Language {
            .ko
        }

        func saveLanguage(_: Language) {}
    }

    private struct PreviewPlaybackRepository: VoiceRecordPlaybackRepository {
        func prepare(audioFilePath _: String)
            throws(VoiceRecordPlaybackRepositoryError) -> AsyncStream<AudioPlaybackState>
        {
            AsyncStream { continuation in
                continuation.yield(AudioPlaybackState(status: .idle, currentTime: 0, duration: 245))
                continuation.finish()
            }
        }

        func play() throws(VoiceRecordPlaybackRepositoryError) {}
        func pause() throws(VoiceRecordPlaybackRepositoryError) {}
        func seek(to _: TimeInterval) throws(VoiceRecordPlaybackRepositoryError) {}
        func stop() throws(VoiceRecordPlaybackRepositoryError) {}
    }

    private struct PreviewWasteBasketRepository: WasteBasketRepository {
        func allClear() throws(DeleteWasteBasketRepositoryError) {}
        func delete(item _: WasteBasketItem) throws(DeleteWasteBasketRepositoryError) {}
        func deleteAll(items _: [WasteBasketItem]) throws(DeleteWasteBasketRepositoryError) {}
        func moveToWasteBasket(item _: WasteBasketItem) throws(MoveWasteBasketRepositoryError) {}
        func moveAllToWasteBasket(items _: [WasteBasketItem]) throws(MoveWasteBasketRepositoryError) {}
        func fetchAll() throws(FetchWasteBasketRepositoryError) -> [WasteBasketItem] {
            []
        }

        func restore(item _: WasteBasketItem) throws(RestoreWasteBasketRepositoryError) {}
        func restoreAll(items _: [WasteBasketItem]) throws(RestoreWasteBasketRepositoryError) {}
    }
#endif
