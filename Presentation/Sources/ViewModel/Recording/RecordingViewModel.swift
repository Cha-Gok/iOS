import Domain
import Foundation

@MainActor
public protocol RecordingCoordinating: AnyObject {
    func cancelRecording()
    func finishRecording(voiceNote: VoiceNote)
}

@MainActor
@Observable
public final class RecordingViewModel {
    struct State: Equatable {
        enum RecordingState {
            case idle
            case recording
            case paused
        }

        let title: String = "새 기록"
        let cancelTitle: String = "취소"
        let completeTitle: String = "종료"
        var recordingStartDate: Date = .now
        var recordingDuration: TimeInterval = 0
        var amplitude: Float = 0
        var recordingState: RecordingState = .idle
        var errorMessage: String?
        var showAlert: Bool = false

        var displayStartDate: String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "yyyy.MM.dd · a HH:mm"

            return formatter.string(from: recordingStartDate)
        }

        var displayDuration: String {
            let duration = Int(recordingDuration)
            let hours = duration / 3600
            let minutes = (duration % 3600) / 60
            let seconds = duration % 60

            return String(format: "%02d : %02d : %02d", hours, minutes, seconds)
        }
    }

    public enum Action {
        case recordButtonTapped
        case cancelButtonTapped
        case finishButtonTapped
        case closeAlertButtonTapped
        case openAlertButtonTapped
        case errorOccurred(Error)
    }

    private let repository: any VoiceRecordRepository
    private let voiceNoteUseCase: any VoiceNoteUseCase

    public weak var coordinator: RecordingCoordinating?

    private(set) var state: State = .init()
    private var waveformTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var actionTask: Task<Void, Never>?

    public init(
        repository: any VoiceRecordRepository,
        voiceNoteUseCase: any VoiceNoteUseCase
    ) {
        self.repository = repository
        self.voiceNoteUseCase = voiceNoteUseCase
    }

    public func send(_ action: Action) {
        switch action {
        case .recordButtonTapped:
            switch state.recordingState {
            case .paused:
                resumeRecording()
            case .recording:
                pauseRecording()
            case .idle:
                startRecording()
            }
        case .cancelButtonTapped:
            stopTimer()
            waveformTask?.cancel()
            waveformTask = nil
            actionTask?.cancel()
            actionTask = Task {
                try? await repository.cancelRecording()
                coordinator?.cancelRecording()
            }
        case .finishButtonTapped:
            actionTask?.cancel()
            actionTask = Task {
                do {
                    stopTimer()
                    waveformTask?.cancel()
                    waveformTask = nil
                    let voiceRecord = try await repository.finishRecording()
                    let voiceNote = try voiceNoteUseCase.create(voiceRecord)
                    coordinator?.finishRecording(voiceNote: voiceNote)
                } catch {
                    send(.errorOccurred(error))
                }
            }
        case .closeAlertButtonTapped:
            state.showAlert = false
        case .openAlertButtonTapped:
            state.showAlert = true
        case .errorOccurred(let error):
            state.errorMessage = error.localizedDescription
        }
    }

    private func startRecording() {
        Task {
            do {
                let waveformStream = try await repository.startRecording()
                state.recordingStartDate = .now
                state.recordingState = .recording
                startTimer()

                waveformTask?.cancel()
                waveformTask = Task { [weak self] in
                    for await waveform in waveformStream {
                        guard let self else { break }
                        state.amplitude = waveform.amplitudes.last ?? 0
                    }
                }
            } catch {
                state.recordingState = .idle
                send(.errorOccurred(error))
            }
        }
    }

    private func pauseRecording() {
        Task {
            do {
                try await repository.pauseRecording()
                stopTimer()
                state.recordingState = .paused
            } catch {
                send(.errorOccurred(error))
            }
        }
    }

    private func resumeRecording() {
        Task {
            do {
                try await repository.resumeRecording()
                startTimer()
                state.recordingState = .recording
            } catch {
                send(.errorOccurred(error))
            }
        }
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self else { return }
                state.recordingDuration += 1
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
}

// MARK: - Preview Data

#if DEBUG
    extension RecordingViewModel {
        public static func preview() -> RecordingViewModel {
            RecordingViewModel(
                repository: PreviewVoiceRecordRepository(),
                voiceNoteUseCase: PreviewVoiceNoteUseCase()
            )
        }

        private struct PreviewVoiceRecordRepository: VoiceRecordRepository {
            func checkMicrophonePermission() -> PermissionStatus {
                .authorized
            }

            func requestMicrophonePermission() async throws(VoiceRecordRepositoryError)
                -> PermissionStatus
            {
                .authorized
            }

            func startRecording() async throws(VoiceRecordRepositoryError) -> AsyncStream<Waveform> {
                AsyncStream { continuation in
                    continuation.finish()
                }
            }

            func pauseRecording() async throws(VoiceRecordRepositoryError) {}
            func resumeRecording() async throws(VoiceRecordRepositoryError) {}
            func finishRecording() async throws(VoiceRecordRepositoryError) -> VoiceRecord {
                VoiceRecord(audioFilePath: "", duration: 0)
            }

            func cancelRecording() async throws(VoiceRecordRepositoryError) {}
        }

        private struct PreviewVoiceNoteUseCase: VoiceNoteUseCase {
            func create(_ voiceRecord: VoiceRecord) throws(VoiceNoteUseCaseError) -> VoiceNote {
                VoiceNote(
                    title: "미리보기 기록",
                    createdAt: .now,
                    updatedAt: .now,
                    folderID: UUID(),
                    voiceRecord: voiceRecord,
                    keywords: [],
                    transcript: nil,
                    summary: nil
                )
            }

            func fetchAllFromDefaultFolder() throws(VoiceNoteUseCaseError) -> [VoiceNote] {
                []
            }

            func fetchAll(folderID: UUID) throws(VoiceNoteUseCaseError) -> [VoiceNote] {
                []
            }

            func fetch(byId id: UUID) throws(VoiceNoteUseCaseError) -> VoiceNote {
                throw .recordNotFound(id)
            }

            func fetchRecent(limit: Int) throws(VoiceNoteUseCaseError) -> [VoiceNote] {
                []
            }

            func update(_ voiceNote: VoiceNote) throws(VoiceNoteUseCaseError) -> VoiceNote {
                voiceNote
            }

            func summarize(
                audioFilePath: String,
                language: Language
            ) async throws(VoiceNoteUseCaseError) -> AudioToSummaryResult {
                AudioToSummaryResult(transcript: Transcript(text: ""), keywords: [], summary: Summary(text: ""))
            }
        }
    }
#endif
