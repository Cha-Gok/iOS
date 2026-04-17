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

    public func send(_ action: Action) {
        switch action {
        case .view(let viewAction):
            switch viewAction {
            case .onAppear:
                setupPalyback()
                fetchFolderName()
                observeVoiceNote()
                switch state.voiceNote.analysisState {
                case .pending, .failed:
                    state.voiceNote.analysisState = .analyzing
                    Task { await performTranscription() }
                case .transcribed:
                    state.voiceNote.analysisState = .analyzing
                    Task { await performSummarization() }
                case .analyzing, .completed:
                    break
                }
            case .onDisappear:
                // 재생 중단 및 리소스 해제
                stop()
            case .playPauseButtonTapped:
                // 현재 재생 중이면 일시정지, 아니면 재생
                if state.currentPlaybackState.status == .playing {
                    pause()
                } else {
                    play()
                }
            case .rewindButtonTapped:
                // 현재 위치에서 skipInterval만큼 뒤로 이동
                seek(to: state.currentPlaybackState.currentTime - Policy.playbackSkipInterval)
            case .forwardButtonTapped:
                // 현재 위치에서 skipInterval만큼 앞으로 이동
                seek(to: state.currentPlaybackState.currentTime + Policy.playbackSkipInterval)
            case .seekBegan:
                // 슬라이더 드래그 시작 — 재생 중이었으면 일시정지하고 상태 보존
                wasPlayingBeforeSeek = state.currentPlaybackState.status == .playing
                if wasPlayingBeforeSeek { pause() }
            case .seekEnded(let time):
                // 슬라이더 드래그 종료 — 목표 위치로 이동 후 드래그 전 재생 상태 복원
                seek(to: time)
                if wasPlayingBeforeSeek {
                    wasPlayingBeforeSeek = false
                    play()
                }
            case .scriptTimestampTapped(let time):
                // 스크립트 타임스탬프 탭 — 해당 시간으로 이동 후 재생
                seek(to: time)
                play()
            case .pop:
                coordinator?.pop()
            case .moveVoiceNoteButtonTapped:
                coordinator?.presentFolderList(with: .single(state.voiceNote))
            case .editButtonTapped:
                state.isEditing = true
            case .doneButtonTapped:
                state.isEditing = false
            // TODO: 제목 저장 구현 필요
            case .deleteVoiceNoteButtonTapped:
                moveToWasteBasket()
            }

        case .internal(let internalAction):
            switch internalAction {
            case .metadataLoaded(let folderName):
                state.folderName = folderName
            case .voiceNoteObserved(let note):
                let folderChanged = state.voiceNote.folderID != note.folderID
                state.voiceNote = note
                if folderChanged { fetchFolderName() }
            case .analysisFailed(let message):
                // AI 분석 실패 — 에러 메시지 표시
                state.errorMessage = message
                state.voiceNote.analysisState = .failed
            case .playbackStateChanged(let playbackState):
                // 재생 진행 스트림에서 수신한 최신 상태 반영
                state.currentPlaybackState = playbackState
                state.updatePlayingParagraph()
            case .errorOccurred(let message):
                // 재생 제어 중 에러 발생 — 알럿 표시
                state.errorMessage = message
            case .errorDismissed:
                // 에러 알럿 닫기
                state.errorMessage = nil
            }
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
        coordinator?.presentFolderList(with: voiceNote)
    }

    public func enterEditing() {
        isEditing = true
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
            transcript: voiceNote.transcript,
            summary: voiceNote.summary,
            analysisState: voiceNote.analysisState
        )

        do {
            _ = try voiceNoteUseCase.update(updatedNote)
            isEditing = false
        } catch {
            errorMessage = "제목 수정에 실패했습니다: \(error.localizedDescription)"
        }
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
