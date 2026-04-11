import Core
import Domain
import Foundation


@MainActor
@Observable
public final class VoiceNoteViewModel {
    public private(set) var state: State

    @ObservationIgnored
    private var playbackObservationTask: Task<Void, Never>?
    @ObservationIgnored
    private var wasPlayingBeforeSeek = false

    // MARK: - UseCases

    private let audioToSummaryUseCase: any AudioToSummaryUseCase
    private let updateVoiceNoteUseCase: any UpdateVoiceNoteUseCase
    private let fetchLanguageUseCase: any FetchLanguageUseCase
    private let fetchFolderUseCase: any FetchFolderUseCase
    private let prepareVoiceRecordPlaybackUseCase: any PrepareVoiceRecordPlaybackUseCase
    private let playVoiceRecordUseCase: any PlayVoiceRecordUseCase
    private let pauseVoiceRecordPlaybackUseCase: any PauseVoiceRecordPlaybackUseCase
    private let seekVoiceRecordPlaybackUseCase: any SeekVoiceRecordPlaybackUseCase
    private let stopVoiceRecordPlaybackUseCase: any StopVoiceRecordPlaybackUseCase

    // MARK: - Init

    public init(
        voiceNote: VoiceNote,
        audioToSummaryUseCase: any AudioToSummaryUseCase,
        updateVoiceNoteUseCase: any UpdateVoiceNoteUseCase,
        fetchLanguageUseCase: any FetchLanguageUseCase,
        fetchFolderUseCase: any FetchFolderUseCase,
        prepareVoiceRecordPlaybackUseCase: any PrepareVoiceRecordPlaybackUseCase,
        playVoiceRecordUseCase: any PlayVoiceRecordUseCase,
        pauseVoiceRecordPlaybackUseCase: any PauseVoiceRecordPlaybackUseCase,
        seekVoiceRecordPlaybackUseCase: any SeekVoiceRecordPlaybackUseCase,
        stopVoiceRecordPlaybackUseCase: any StopVoiceRecordPlaybackUseCase
    ) {
        state = State(voiceNote: voiceNote)
        self.audioToSummaryUseCase = audioToSummaryUseCase
        self.updateVoiceNoteUseCase = updateVoiceNoteUseCase
        self.fetchLanguageUseCase = fetchLanguageUseCase
        self.fetchFolderUseCase = fetchFolderUseCase
        self.prepareVoiceRecordPlaybackUseCase = prepareVoiceRecordPlaybackUseCase
        self.playVoiceRecordUseCase = playVoiceRecordUseCase
        self.pauseVoiceRecordPlaybackUseCase = pauseVoiceRecordPlaybackUseCase
        self.seekVoiceRecordPlaybackUseCase = seekVoiceRecordPlaybackUseCase
        self.stopVoiceRecordPlaybackUseCase = stopVoiceRecordPlaybackUseCase
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
                if state.analysisState != .completed {
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
            }

        case .internal(let internalAction):
            switch internalAction {
            case .metadataLoaded(let folderName):
                // 폴더명 비동기 로드 완료
                state.folderName = folderName
            case .analysisCompleted(let note):
                // AI 분석 완료 — keywords/transcript/summary가 채워진 노트로 교체
                state.voiceNote = note
                state.analysisState = .completed
            case .analysisFailed(let message):
                // AI 분석 실패 — 에러 메시지 표시
                state.errorMessage = message
                state.analysisState = .failed
            case .playbackStateChanged(let playbackState):
                // 재생 진행 스트림에서 수신한 최신 상태 반영
                state.currentPlaybackState = playbackState
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
            let folderName = try await fetchFolderUseCase.fetch(by: state.voiceNote.folderID).name
            send(.internal(.metadataLoaded(folderName: folderName)))
        } catch {
            AppLogger.error(error)
        }
    }

    private func performNewAnalysis() async {
        do {
            let language = try await fetchLanguageUseCase.execute()
            let result = try await audioToSummaryUseCase.execute(
                audioFileURL: state.voiceNote.voiceRecord.audioFilePath,
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
                summary: result.summary
            )

            // 분석 결과 반영 (폴더명은 metadataLoaded 액션이 별도로 담당)
            let finalNote = try await updateVoiceNoteUseCase.execute(updated)
            send(.internal(.analysisCompleted(note: finalNote)))
        } catch {
            send(.internal(.analysisFailed(error.localizedDescription)))
        }
    }

    private func startPlaybackObservation() {
        playbackObservationTask?.cancel()
        playbackObservationTask = nil
        do {
            let stream = try prepareVoiceRecordPlaybackUseCase.execute(
                audioFileURL: state.voiceNote.voiceRecord.audioFilePath
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
            try stopVoiceRecordPlaybackUseCase.execute()
        } catch {
            send(.internal(.errorOccurred(error.localizedDescription)))
        }
    }

    private func play() {
        do {
            try playVoiceRecordUseCase.execute()
        } catch {
            send(.internal(.errorOccurred(error.localizedDescription)))
        }
    }

    private func pause() {
        do {
            try pauseVoiceRecordPlaybackUseCase.execute()
        } catch {
            send(.internal(.errorOccurred(error.localizedDescription)))
        }
    }

    private func seek(to time: TimeInterval) {
        do {
            try seekVoiceRecordPlaybackUseCase.execute(time: time)
        } catch {
            send(.internal(.errorOccurred(error.localizedDescription)))
        }
    }
}

// MARK: - Nested Types

public extension VoiceNoteViewModel {
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
        public enum AnalysisState {
            case analyzing
            case completed
            case failed
        }

        var voiceNote: VoiceNote
        var analysisState: AnalysisState
        var errorMessage: String?
        var folderName: String = ""
        var currentPlaybackState = AudioPlaybackState(
            status: .idle,
            currentTime: 0,
            duration: 0
        )

        init(voiceNote: VoiceNote) {
            self.voiceNote = voiceNote
            analysisState = voiceNote.summary != nil && voiceNote.transcript != nil ? .completed : .analyzing
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
            guard let transcript = voiceNote.transcript else { return [] }
            // 레거시 데이터 (세그먼트 없음) — 기존 방식 유지
            guard !transcript.segments.isEmpty else {
                let paragraphs = transcript.text
                    .components(separatedBy: "\n\n")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                return [ScriptSection(timestamp: 0, paragraphs: paragraphs)]
            }
            return Self.groupSegmentsIntoSections(transcript.segments)
        }

        // MARK: - Segment Grouping

        /// 세그먼트를 공백 임계값 기준으로 섹션들로 그룹화
        private static func groupSegmentsIntoSections(_ segments: [TranscriptSegment]) -> [ScriptSection] {
            guard let first = segments.first else { return [] }

            var sections: [ScriptSection] = []
            var currentTimestamp = first.timestamp
            var currentWords: [String] = [first.substring]

            for i in 1..<segments.count {
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
