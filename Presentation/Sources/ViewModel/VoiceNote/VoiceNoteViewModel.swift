import Core
import Domain
import Foundation

@MainActor
public protocol VoiceNoteCoordinatorDelegate: AnyObject {
    func pop()
    func presentMoveFolder(for voiceNote: VoiceNote, onComplete: ((String) -> Void)?)
}

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
    public private(set) var searchMode: Bool = false
    public private(set) var searchQuery: String = ""
    public private(set) var currentMatchIndex: Int = 0
    public private(set) var isMLXModelSupported: Bool = (ChaGokModelSupport.current.model != .none)

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
    private let availableSupportModelRepository: any AvailableModelSupportRepository

    // MARK: - Init

    public init(
        voiceNote: VoiceNote,
        voiceNoteUseCase: any VoiceNoteUseCase,
        folderUseCase: any FolderUseCase,
        playbackRepository: any VoiceRecordPlaybackRepository,
        availableSupportModelRepository: any AvailableModelSupportRepository
    ) {
        self.voiceNote = voiceNote
        self.voiceNoteUseCase = voiceNoteUseCase
        self.folderUseCase = folderUseCase
        self.playbackRepository = playbackRepository
        self.availableSupportModelRepository = availableSupportModelRepository
    }

    // MARK: - View Actions

    public func onAppear() {
        setupPlayback()
        fetchFolderName()
        observeVoiceNote()
        checkMLXSupport()
    }

    private func checkMLXSupport() {
        Task {
            let support = await availableSupportModelRepository.checkMLXSupportModel()
            self.isMLXModelSupported = (support.model != .none)
        }
    }

    public func onDisappear() {
        playbackObservationTask?.cancel()
        playbackObservationTask = nil
        voiceNoteObservationTask?.cancel()
        voiceNoteObservationTask = nil
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

    public func moveVoiceNote(onComplete: ((String) -> Void)? = nil) {
        coordinator?.presentMoveFolder(for: voiceNote, onComplete: onComplete)
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
        guard currentPage != page else { return }
        currentPage = page
        if searchMode {
            currentMatchIndex = 0
        }
    }

    public func enterSearchMode() {
        guard !searchMode else { return }
        searchMode = true
        searchQuery = ""
        currentMatchIndex = 0
        if currentPlaybackState.status == .playing { pause() }
    }

    public func exitSearchMode() {
        guard searchMode else { return }
        searchMode = false
        searchQuery = ""
        currentMatchIndex = 0
    }

    public func updateSearchQuery(_ query: String) {
        searchQuery = query
        currentMatchIndex = 0
    }

    public func nextMatch() {
        let count = currentPageMatches.count
        guard count > 0 else { return }
        currentMatchIndex = (currentMatchIndex + 1) % count
    }

    public func previousMatch() {
        let count = currentPageMatches.count
        guard count > 0 else { return }
        currentMatchIndex = (currentMatchIndex - 1 + count) % count
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

        var updatedNote = voiceNote
        updatedNote.title = trimmedTitle
        updatedNote.updatedAt = .now

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

        var updatedNote = voiceNote
        updatedNote.transcript = updatedTranscript
        updatedNote.updatedAt = .now

        do {
            voiceNote = try voiceNoteUseCase.update(updatedNote)
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
        if searchMode { exitSearchMode() }
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
                for await note in stream {
                    let folderChanged = voiceNote.folderID != note.folderID
                    voiceNote = note
                    if folderChanged { fetchFolderName() }
                }
            } catch {
                errorMessage = error.localizedDescription
            }
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

    private func stop() {
        do {
            try playbackRepository.stop()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func moveToWasteBasket() {
        do {
            stop()
            try voiceNoteUseCase.moveToTrash(noteID: voiceNote.id)
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
        guard editingMode == .script else { return false }
        return editableScriptSections != (voiceNote.transcript?.sections ?? [])
    }

    var isSummaryOutdated: Bool {
        voiceNote.isSummaryOutdated
    }

    /// 요약 페이지에서 매치되는 항목 목록. 핵심 포인트 → 키워드 순서로 정렬됩니다.
    var summaryMatches: [VoiceNoteSearchMatch] {
        guard !searchQuery.isEmpty else { return [] }
        var matches: [VoiceNoteSearchMatch] = []
        for (index, point) in keyPoints.enumerated() {
            for range in point.text.ranges(of: searchQuery) {
                matches.append(.init(location: .keyPoint(index: index), range: range))
            }
        }
        for (index, keyword) in keywords.enumerated() {
            for range in keyword.ranges(of: searchQuery) {
                matches.append(.init(location: .keyword(index: index), range: range))
            }
        }
        return matches
    }

    /// 스크립트 페이지에서 매치되는 항목 목록. 섹션 순서 → 섹션 내 위치 순서로 정렬됩니다.
    var scriptMatches: [VoiceNoteSearchMatch] {
        guard !searchQuery.isEmpty else { return [] }
        var matches: [VoiceNoteSearchMatch] = []
        for (index, section) in scriptSections.enumerated() {
            for range in section.text.ranges(of: searchQuery) {
                matches.append(.init(location: .script(sectionIndex: index), range: range))
            }
        }
        return matches
    }

    /// 현재 페이지에 해당하는 매치 목록.
    var currentPageMatches: [VoiceNoteSearchMatch] {
        currentPage == .summary ? summaryMatches : scriptMatches
    }

    /// 현재 포커스된 매치.
    var currentMatch: VoiceNoteSearchMatch? {
        let matches = currentPageMatches
        guard matches.indices.contains(currentMatchIndex) else { return nil }
        return matches[currentMatchIndex]
    }

    /// 매치 카운트 표시 문자열 ("현재 / 전체" 포맷, 매치 없으면 "0 / 0").
    var matchCountText: String {
        let total = currentPageMatches.count
        let display = total > 0 ? currentMatchIndex + 1 : 0
        return "\(display) / \(total)"
    }

    /// 현재 페이지에 매치가 하나 이상 있는지 여부.
    var hasCurrentPageMatches: Bool {
        !currentPageMatches.isEmpty
    }

    /// 세그먼트에 표시할 요약 매치 수. 검색 모드가 아니거나 쿼리가 비어 있으면 `nil`을 반환해 카운트를 숨깁니다.
    var summaryMatchCount: Int? {
        searchMode && !searchQuery.isEmpty ? summaryMatches.count : nil
    }

    /// 세그먼트에 표시할 스크립트 매치 수. 검색 모드가 아니거나 쿼리가 비어 있으면 `nil`을 반환해 카운트를 숨깁니다.
    var scriptMatchCount: Int? {
        searchMode && !searchQuery.isEmpty ? scriptMatches.count : nil
    }

    /// 현재 검색 쿼리에 매칭되는 범위를 반환합니다.
    func highlightRanges(in text: String) -> [NSRange] {
        text.ranges(of: searchQuery)
    }

    /// 지정한 핵심 포인트 인덱스가 현재 포커스된 매치이면 해당 범위를 반환합니다.
    func focusedKeyPointRange(at index: Int) -> NSRange? {
        guard let match = currentMatch,
              case .keyPoint(let idx) = match.location,
              idx == index else { return nil }
        return match.range
    }

    /// 현재 포커스된 매치가 키워드이면 (키워드 인덱스, 범위)를 반환합니다.
    func focusedKeywordMatch() -> (index: Int, range: NSRange)? {
        guard let match = currentMatch,
              case .keyword(let idx) = match.location else { return nil }
        return (idx, match.range)
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
