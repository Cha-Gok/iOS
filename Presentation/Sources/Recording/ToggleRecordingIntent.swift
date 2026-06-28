import ActivityKit
import AppIntents
import Core
import Foundation
import Domain

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
        
        let isPaused = activity.content.state.isPaused
        AppLogger.info("isPaused : \(isPaused)")
        if isPaused {
            DarwinNotificationCenter.post(.resumeRecording)
        } else {
            DarwinNotificationCenter.post(.pauseRecording)
        }
        
        return .result()
    }
}
