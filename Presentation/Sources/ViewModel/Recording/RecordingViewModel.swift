import ActivityKit
import Core
import Domain
import Foundation

@MainActor
public protocol RecordingCoordinating: AnyObject {
    func cancelRecording()
    func finishRecording(voiceNote: VoiceNote)
}

extension Activity: @unchecked @retroactive Sendable {}

@MainActor
@Observable
public final class RecordingViewModel {
    private var activeActivity: Activity<RecordingActivityAttributes>?

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
        case viewDidAppear
        case recordButtonTapped
        case openCancelAlertButtonTapped
        case openCompleteAlertButtonTapped
        case cancelButtonTapped
        case finishButtonTapped
        case errorOccurred(Error)
    }

    private let repository: any VoiceRecordRepository
    private let voiceNoteUseCase: any VoiceNoteUseCase

    public weak var coordinator: RecordingCoordinating?
    public weak var alertCoordinator: ChaGokAlertCoordinatorDelegate?
    public var showCancelAlert: (() -> Void)?
    public var showCompleteAlert: (() -> Void)?

    var state: State = .init()
    private var waveformTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var actionTask: Task<Void, Never>?
    private var amplitudeUpdateTask: Task<Void, Never>?
    private var darwinObservations: [DarwinNotificationObservation] = []

    public init(
        repository: any VoiceRecordRepository,
        voiceNoteUseCase: any VoiceNoteUseCase
    ) {
        self.repository = repository
        self.voiceNoteUseCase = voiceNoteUseCase
        // 앱이 백그라운드에서 재시작되거나 뷰모델이 다시 생성되었을 때 기존 활성화된 Live Activity 인스턴스 참조를 복원합니다.
        activeActivity = Activity<RecordingActivityAttributes>.activities.first
        subscribeToWidgetNotifications()
    }

    public func send(_ action: Action) {
        switch action {
        case .viewDidAppear:
            guard state.recordingState == .idle else { return }
            startRecording()
        case .recordButtonTapped:
            switch state.recordingState {
            case .paused:
                resumeRecording()
            case .recording:
                pauseRecording()
            case .idle:
                startRecording()
            }
        case .openCancelAlertButtonTapped:
            if state.recordingDuration <= 3 {
                send(.cancelButtonTapped)
            } else {
                showCancelAlert?()
            }
        case .openCompleteAlertButtonTapped:
            showCompleteAlert?()
        case .cancelButtonTapped:
            stopTimer()
            stopAmplitudeUpdates()
            waveformTask?.cancel()
            waveformTask = nil
            endLiveActivity()
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
                    stopAmplitudeUpdates()
                    waveformTask?.cancel()
                    waveformTask = nil
                    endLiveActivity()
                    let voiceRecord = try await repository.finishRecording()
                    let voiceNote = try voiceNoteUseCase.create(voiceRecord)
                    coordinator?.finishRecording(voiceNote: voiceNote)
                } catch {
                    send(.errorOccurred(error))
                }
            }
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
                startLiveActivity()
                startAmplitudeUpdates()

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
                stopAmplitudeUpdates()
                state.recordingState = .paused
                updateLiveActivity(isPaused: true)
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
                startAmplitudeUpdates()
                state.recordingState = .recording
                updateLiveActivity(isPaused: false)
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

    // MARK: - Live Activity Amplitude Update

    /// Live Activity에 amplitude를 주기적으로 반영합니다.
    /// ActivityKit는 업데이트 빈도에 제한이 있으므로 1초 간격으로 업데이트합니다.
    private func startAmplitudeUpdates() {
        amplitudeUpdateTask?.cancel()
        amplitudeUpdateTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self else { return }
                updateLiveActivity(isPaused: false)
            }
        }
    }

    private func stopAmplitudeUpdates() {
        amplitudeUpdateTask?.cancel()
        amplitudeUpdateTask = nil
    }

    // MARK: - Live Activity

    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = RecordingActivityAttributes(
            title: state.title,
            startDate: state.displayStartDate
        )

        let initialContentState = RecordingActivityAttributes.ContentState(
            duration: state.recordingDuration,
            isPaused: false,
            amplitude: state.amplitude
        )

        let content = ActivityContent(state: initialContentState, staleDate: nil)

        do {
            activeActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            AppLogger.error("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    private func updateLiveActivity(isPaused: Bool) {
        guard let activeActivity else { return }

        let updatedContentState = RecordingActivityAttributes.ContentState(
            duration: state.recordingDuration,
            isPaused: isPaused,
            amplitude: state.amplitude
        )

        let content = ActivityContent(state: updatedContentState, staleDate: nil)

        Task { @MainActor in
            await activeActivity.update(content)
        }
    }

    private func endLiveActivity() {
        guard let activeActivity else { return }

        let finalContentState = RecordingActivityAttributes.ContentState(
            duration: state.recordingDuration,
            isPaused: state.recordingState == .paused,
            amplitude: state.amplitude
        )

        let content = ActivityContent(state: finalContentState, staleDate: nil)

        Task { @MainActor in
            await activeActivity.end(content, dismissalPolicy: .immediate)
            self.activeActivity = nil
        }
    }

    // MARK: - Widget IPC (Darwin Notification)

    /// Widget Extension에서 보내는 Darwin Notification을 구독합니다.
    /// NotificationCenter.default는 동일 프로세스 내에서만 작동하므로,
    /// 별도 프로세스인 Widget Extension과는 Darwin Notification을 사용합니다.
    private func subscribeToWidgetNotifications() {
        let pauseObservation = DarwinNotificationCenter.observe(.pauseRecording) { [weak self] in
            Task { @MainActor [weak self] in
                self?.handlePauseFromWidget()
            }
        }
        let resumeObservation = DarwinNotificationCenter.observe(.resumeRecording) { [weak self] in
            Task { @MainActor [weak self] in
                self?.handleResumeFromWidget()
            }
        }
        darwinObservations = [pauseObservation, resumeObservation]
    }

    @MainActor
    private func handlePauseFromWidget() {
        guard state.recordingState == .recording else { return }
        pauseRecording()
    }

    @MainActor
    private func handleResumeFromWidget() {
        guard state.recordingState == .paused else { return }
        resumeRecording()
    }
}
