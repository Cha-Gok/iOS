import ActivityKit
import AppIntents
import Core
import Domain
import Foundation

public struct ToggleRecordingIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = "녹음 재생/일시정지 토글"

    public init() {}

    public func perform() async throws -> some IntentResult {
        // 현재 활성화된 Live Activity를 가져와 일시정지 상태에 맞는 Darwin Notification을 전송합니다.
        // NotificationCenter.default는 프로세스 내(in-process) 통신만 가능하므로,
        // Widget Extension → 메인 앱 간 통신에는 Darwin Notification을 사용해야 합니다.
        guard let activity = Activity<RecordingActivityAttributes>.activities.first else {
            return .result()
        }

        let currentIsPaused = activity.content.state.isPaused
        let newIsPaused = !currentIsPaused

        AppLogger.info("Widget Toggle - currentIsPaused: \(currentIsPaused) -> newIsPaused: \(newIsPaused)")

        // 1. Widget Extension에서 직접 Live Activity 상태를 먼저 업데이트하여 즉각적인 UI 반응을 확보합니다.
        let updatedState = RecordingActivityAttributes.ContentState(
            duration: activity.content.state.duration,
            isPaused: newIsPaused,
            amplitude: activity.content.state.amplitude
        )
        let content = ActivityContent(state: updatedState, staleDate: nil)
        await activity.update(content)

        // 2. 메인 앱에 상태 변경을 알려 실제 녹음 동작을 동기화합니다.
        if newIsPaused {
            DarwinNotificationCenter.post(.pauseRecording)
        } else {
            DarwinNotificationCenter.post(.resumeRecording)
        }

        return .result()
    }
}
