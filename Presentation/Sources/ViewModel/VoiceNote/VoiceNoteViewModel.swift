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
    public private(set) var isEditing: Bool = false
    public private(set) var currentPlaybackState = AudioPlaybackState(status: .idle, currentTime: 0, duration: 0)
    public private(set) var playingParagraphInfo: PlayingParagraphInfo?
    /// State가 struct이 아니므로 let으로 선언해 참조 안정성을 보장합니다.
    public let playbackHighlight = PlaybackHighlight()
    public private(set) var editableScriptSections: [ScriptSection] = []

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

    public func enterEditing() {
        editableScriptSections = scriptSections
        isEditing = true
    }

    public func updateScriptParagraph(sectionIndex: Int, paragraphIndex: Int, text: String) {
        guard sectionIndex < editableScriptSections.count,
              paragraphIndex < editableScriptSections[sectionIndex].paragraphs.count else { return }
        var sections = editableScriptSections
        var paragraphs = sections[sectionIndex].paragraphs
        paragraphs[paragraphIndex] = text
        sections[sectionIndex] = ScriptSection(timestamp: sections[sectionIndex].timestamp, paragraphs: paragraphs)
        editableScriptSections = sections
    }

    public func doneEditing(title: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty, trimmedTitle != voiceNote.title else {
            isEditing = false
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
            transcript: makeUpdatedTranscript(),
            summary: voiceNote.summary,
            analysisState: voiceNote.analysisState
        )

        do {
            _ = try voiceNoteUseCase.update(updatedNote)
            self.voiceNote = updatedNote
            isEditing = false
        } catch {
            errorMessage = "제목 수정에 실패했습니다: \(error.localizedDescription)"
        }
    }

    private func makeUpdatedTranscript() -> Transcript? {
        guard let original = voiceNote.transcript else { return nil }
        
        let segments = editableScriptSections.flatMap { section in
            section.paragraphs.map { pText in
                TranscriptSegment(substring: pText, timestamp: section.timestamp, duration: 0)
            }
        }
        
        return Transcript(
            id: original.id,
            createdAt: original.createdAt,
            text: segments.map(\.substring).joined(separator: "\n"),
            segments: segments
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
            guard playingParagraphInfo != nil else { return }
            playingParagraphInfo = nil
            playbackHighlight.playingParagraphInfo = nil
            return
        }

        var newInfo: PlayingParagraphInfo?
        for (index, section) in sections.enumerated().reversed() {
            if section.timestamp <= currentTime {
                newInfo = PlayingParagraphInfo(sectionIndex: index, paragraphIndex: 0)
                break
            }
        }
        guard playingParagraphInfo != newInfo else { return }
        playingParagraphInfo = newInfo
        playbackHighlight.playingParagraphInfo = newInfo
    }

    private static func groupSegmentsIntoSections(_ segments: [TranscriptSegment]) -> [ScriptSection] {
        guard let first = segments.first else { return [] }

        var sections: [ScriptSection] = []
        var currentTimestamp = first.timestamp
        var currentWords: [String] = [first.substring]

        for i in 1 ..< segments.count {
            let prev = segments[i - 1]
            let curr = segments[i]
            let gap = curr.timestamp - (prev.timestamp + prev.duration)

            if gap > Policy.scriptGroupingPauseThreshold {
                let paragraph = currentWords.joined(separator: " ")
                sections.append(ScriptSection(timestamp: currentTimestamp, paragraphs: [paragraph]))
                currentTimestamp = curr.timestamp
                currentWords = [curr.substring]
            } else {
                currentWords.append(curr.substring)
            }
        }

        if !currentWords.isEmpty {
            let paragraph = currentWords.joined(separator: " ")
            sections.append(ScriptSection(timestamp: currentTimestamp, paragraphs: [paragraph]))
        }

        return sections
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
        voiceNote.keywords.map(\.word)
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

    var scriptSections: [ScriptSection] {
        if isEditing { return editableScriptSections }
        guard let transcript = voiceNote.transcript, !transcript.segments.isEmpty else { return [] }
        return Self.groupSegmentsIntoSections(transcript.segments)
    }
}

// MARK: - Nested Types

public extension VoiceNoteViewModel {
    @Observable
    final class PlaybackHighlight {
        public var playingParagraphInfo: PlayingParagraphInfo?
    }

    struct PlayingParagraphInfo: Equatable {
        public let sectionIndex: Int
        public let paragraphIndex: Int
    }

    enum Section: Int, CaseIterable, Sendable {
        case metadata
        case keyPoints
        case keywords
        case scripts

        public var title: String? {
            switch self {
            case .keyPoints: return "AI 요약"
            case .keywords: return "키워드"
            case .scripts: return "스크립트"
            default: return nil
            }
        }

        public var headerTitle: String? {
            switch self {
            case .keyPoints: return "핵심 포인트"
            case .keywords: return "키워드"
            case .scripts: return "스크립트"
            default: return nil
            }
        }
    }

    enum Item: Hashable, Sendable {
        case metadata
        case keyPoint(number: Int, text: String)
        case keywords
        case script(index: Int)
    }
}
