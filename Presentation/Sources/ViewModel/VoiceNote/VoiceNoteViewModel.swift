import Core
import Domain
import Foundation

public protocol VoiceNoteCoordinatorDelegate: BaseCoordinatorDelegate {
    func presentFolderList(with: VoiceNote)
}

@MainActor
@Observable
public final class VoiceNoteViewModel {
    public private(set) var state: State

    @ObservationIgnored
    private var playbackObservationTask: Task<Void, Never>?
    @ObservationIgnored
    private var wasPlayingBeforeSeek = false
    public weak var coordinator: VoiceNoteCoordinatorDelegate?

    // MARK: - UseCases

    private let voiceNoteUseCase: any VoiceNoteUseCase
    private let folderUseCase: any FolderUseCase
    private let languageRepository: any LanguageRepository
    private let playbackRepository: any VoiceRecordPlaybackRepository

    // MARK: - Init

    public init(
        voiceNote: VoiceNote,
        voiceNoteUseCase: any VoiceNoteUseCase,
        folderUseCase: any FolderUseCase,
        languageRepository: any LanguageRepository,
        playbackRepository: any VoiceRecordPlaybackRepository
    ) {
        state = State(voiceNote: voiceNote)
        self.voiceNoteUseCase = voiceNoteUseCase
        self.folderUseCase = folderUseCase
        self.languageRepository = languageRepository
        self.playbackRepository = playbackRepository
    }

    deinit {
        playbackObservationTask?.cancel()
    }

    // MARK: - Send

    public func send(_ action: Action) {
        switch action {
        case .view(let viewAction):
            switch viewAction {
            case .onAppear:
                // 재생 스트림 구독 시작 및 폴더명·AI 분석 로드
                startPlaybackObservation()
                Task { await fetchFolderName() }
                if state.voiceNote.analysisState != .completed {
                    state.voiceNote.analysisState = .analyzing
                    Task { await performNewAnalysis() }
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
                coordinator?.presentFolderList(with: state.voiceNote)
            }

        case .internal(let internalAction):
            switch internalAction {
            case .metadataLoaded(let folderName):
                // 폴더명 비동기 로드 완료
                state.folderName = folderName
            case .analysisCompleted(let note):
                // AI 분석 완료 — keywords/transcript/summary가 채워진 노트로 교체
                state.voiceNote = note
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

    // MARK: - Private Methods

    private func fetchFolderName() async {
        do {
            let folderName = try await folderUseCase.fetch(by: state.voiceNote.folderID).name
            send(.internal(.metadataLoaded(folderName: folderName)))
        } catch {
            AppLogger.error(error)
        }
    }

    private func performNewAnalysis() async {
        do {
            let language = languageRepository.fetchLanguage()
            let result = try await voiceNoteUseCase.summarize(
                audioFilePath: state.voiceNote.voiceRecord.audioFilePath,
                language: language
            )
            let updated = VoiceNote(
                id: state.voiceNote.id,
                title: state.voiceNote.title,
                createdAt: state.voiceNote.createdAt,
                updatedAt: .now,
                folderID: state.voiceNote.folderID,
                voiceRecord: state.voiceNote.voiceRecord,
                keywords: result.keywords,
                transcript: result.transcript,
                summary: result.summary,
                analysisState: .completed
            )

            // 분석 결과 반영 (폴더명은 metadataLoaded 액션이 별도로 담당)
            let finalNote = try await voiceNoteUseCase.update(updated)
            send(.internal(.analysisCompleted(note: finalNote)))
        } catch {
            send(.internal(.analysisFailed(error.localizedDescription)))
        }
    }

    private func startPlaybackObservation() {
        playbackObservationTask?.cancel()
        playbackObservationTask = nil
        do {
            let stream = try playbackRepository.prepare(
                audioFilePath: state.voiceNote.voiceRecord.audioFilePath
            )
            playbackObservationTask = Task {
                for await playbackState in stream {
                    send(.internal(.playbackStateChanged(playbackState)))
                }
            }
        } catch {
            send(.internal(.errorOccurred(error.localizedDescription)))
        }
    }

    private func stop() {
        playbackObservationTask?.cancel()
        playbackObservationTask = nil
        do {
            try playbackRepository.stop()
        } catch {
            send(.internal(.errorOccurred(error.localizedDescription)))
        }
    }

    private func play() {
        do {
            try playbackRepository.play()
        } catch {
            send(.internal(.errorOccurred(error.localizedDescription)))
        }
    }

    private func pause() {
        do {
            try playbackRepository.pause()
        } catch {
            send(.internal(.errorOccurred(error.localizedDescription)))
        }
    }

    private func seek(to time: TimeInterval) {
        do {
            try playbackRepository.seek(to: time)
        } catch {
            send(.internal(.errorOccurred(error.localizedDescription)))
        }
    }
}

// MARK: - Nested Types

public extension VoiceNoteViewModel {
    /// 재생 위치에 따른 하이라이트 상태. 셀이 직접 관찰합니다.
    @Observable
    final class PlaybackHighlight {
        public var playingParagraphInfo: State.PlayingParagraphInfo?
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

    enum Action {
        public enum View {
            case onAppear
            case onDisappear
            case playPauseButtonTapped
            case rewindButtonTapped
            case forwardButtonTapped
            case seekBegan
            case seekEnded(TimeInterval)
            case scriptTimestampTapped(TimeInterval)
            case pop
            case moveVoiceNoteButtonTapped
        }

        public enum Internal {
            case metadataLoaded(folderName: String)
            case analysisCompleted(note: VoiceNote)
            case analysisFailed(String)
            case playbackStateChanged(AudioPlaybackState)
            case errorOccurred(String)
            case errorDismissed
        }

        case view(View)
        case `internal`(Internal)
    }

    struct State {
        var voiceNote: VoiceNote
        var errorMessage: String?
        var folderName: String = ""
        /// State가 struct이므로 let으로 선언해 참조 안정성을 보장합니다.
        let playbackHighlight = PlaybackHighlight()
        var currentPlaybackState = AudioPlaybackState(status: .idle, currentTime: 0, duration: 0)

        init(voiceNote: VoiceNote) {
            self.voiceNote = voiceNote
        }

        // MARK: - Highlight Logic

        /// 현재 재생 중인 문단의 정보를 담는 구조체
        public struct PlayingParagraphInfo: Equatable {
            public let sectionIndex: Int
            public let paragraphIndex: Int
        }

        /// 현재 하이라이트된 문단 정보
        public private(set) var playingParagraphInfo: PlayingParagraphInfo?

        /// 재생 시간에 따라 하이라이트 정보를 업데이트합니다.
        /// - Note: `@Observable`은 값이 같아도 setter 호출 시 observation을 fire하므로,
        ///   동일 값이면 early return하여 visible cell의 불필요한 `updateProperties()` 호출을 방지합니다.
        mutating func updatePlayingParagraph() {
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
            guard playingParagraphInfo != newInfo else {
                return
            }
            playingParagraphInfo = newInfo
            playbackHighlight.playingParagraphInfo = newInfo
        }

        // MARK: - Mapped Properties

        public var title: String {
            voiceNote.title
        }

        public var metadataText1: String {
            let created = voiceNote.createdAt.toString(format: "yyyy.MM.dd · a HH:mm")
            guard voiceNote.createdAt != voiceNote.updatedAt else { return created }
            let updated = voiceNote.updatedAt.toString(format: "yyyy.MM.dd")
            return "\(created) (\(updated) 수정됨)"
        }

        public var metadataText2: String {
            voiceNote.voiceRecord.duration.koreanDurationString
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
            guard let transcript = voiceNote.transcript, !transcript.segments.isEmpty else { return [] }
            return Self.groupSegmentsIntoSections(transcript.segments)
        }

        // MARK: - Segment Grouping

        /// 세그먼트를 공백 임계값 기준으로 섹션들로 그룹화
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
                    // 현재까지 모은 단어들을 하나의 문단으로 완성
                    let paragraph = currentWords.joined(separator: " ")
                    sections.append(ScriptSection(timestamp: currentTimestamp, paragraphs: [paragraph]))
                    // 새 섹션 시작
                    currentTimestamp = curr.timestamp
                    currentWords = [curr.substring]
                } else {
                    currentWords.append(curr.substring)
                }
            }

            // 마지막 섹션 추가
            if !currentWords.isEmpty {
                let paragraph = currentWords.joined(separator: " ")
                sections.append(ScriptSection(timestamp: currentTimestamp, paragraphs: [paragraph]))
            }

            return sections
        }
    }
}
