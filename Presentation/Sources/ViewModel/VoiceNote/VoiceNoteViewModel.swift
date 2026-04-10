import Domain
import Foundation

public struct KeyPoint: Hashable {
    let number: Int
    let text: String
}

public struct ScriptSection: Hashable {
    let timestamp: String
    let paragraphs: [String]
}

@MainActor
@Observable
public final class VoiceNoteViewModel {
    public enum Section: Int, CaseIterable, Sendable {
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

    public enum Item: Hashable, Sendable {
        case metadata
        case keyPoint(number: Int, text: String)
        case keywords
        case script(index: Int)
    }

    public struct State {
        public enum AnalysisState {
            case analyzing
            case completed
            case failed
        }

        var voiceNote: VoiceNote
        var analysisState: AnalysisState = .analyzing
        var errorMessage: String?
        var folderName: String = ""
        var currentPlaybackState = AudioPlaybackState(
            status: .idle,
            currentTime: 0,
            duration: 0
        )

        // MARK: - Mapped Properties

        public var title: String {
            voiceNote.title
        }

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

        public let tabSections: [Section] = [.keyPoints, .keywords, .scripts]
        public var tabTitles: [String] {
            tabSections.compactMap { $0.title }
        }
    }

    public enum Action {
        case onAppear
        case onDisappear
        case playButtonTapped
        case pauseButtonTapped
        case seek(TimeInterval)
    }

    // MARK: - Properties

    public private(set) var state: State

    @ObservationIgnored private var playbackObservationTask: Task<Void, Never>?

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
        case .onAppear:
            startAnalysis()
            preparePlayback()
        case .onDisappear:
            stop()
        case .playButtonTapped:
            play()
        case .pauseButtonTapped:
            pause()
        case let .seek(time):
            seek(to: time)
        }
    }

    // MARK: - Private Methods

    private func startAnalysis() {
        Task {
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
                let folderID = state.voiceNote.folderID
                async let folderName = fetchFolderUseCase.fetch(by: folderID).name
                async let updatedNote = updateVoiceNoteUseCase.execute(updated)
                state.folderName = try await folderName
                state.voiceNote = try await updatedNote
                state.analysisState = .completed
            } catch {
                state.errorMessage = error.localizedDescription
                state.analysisState = .failed
            }
        }
    }

    private func preparePlayback() {
        Task {
            do {
                let stream = try await prepareVoiceRecordPlaybackUseCase.execute(
                    audioFileURL: state.voiceNote.voiceRecord.audioFilePath
                )
                playbackObservationTask = Task {
                    for await playbackState in stream {
                        state.currentPlaybackState = playbackState
                    }
                }
            } catch {
                state.errorMessage = error.localizedDescription
            }
        }
    }

    private func stop() {
        playbackObservationTask?.cancel()
        playbackObservationTask = nil
        Task {
            do {
                try await stopVoiceRecordPlaybackUseCase.execute()
            } catch {
                state.errorMessage = error.localizedDescription
            }
        }
    }

    private func play() {
        Task {
            do {
                try await playVoiceRecordUseCase.execute()
            } catch {
                state.errorMessage = error.localizedDescription
            }
        }
    }

    private func pause() {
        Task {
            do {
                try await pauseVoiceRecordPlaybackUseCase.execute()
            } catch {
                state.errorMessage = error.localizedDescription
            }
        }
    }

    private func seek(to time: TimeInterval) {
        Task {
            do {
                try await seekVoiceRecordPlaybackUseCase.execute(time: time)
            } catch {
                state.errorMessage = error.localizedDescription
            }
        }
    }
}
