import Foundation

/// 프로세스 간(IPC) 통신을 위한 Darwin Notification 헬퍼입니다.
/// Widget Extension ↔ 메인 앱 간 통신에 사용합니다.
/// NotificationCenter.default는 동일 프로세스 내에서만 작동하므로,
/// 별도 프로세스인 Widget Extension과는 Darwin Notification을 사용해야 합니다.
public enum DarwinNotificationCenter {

    /// Darwin Notification 이름 정의
    public enum Name: String {
        case pauseRecording = "com.chagok.recording.pause"
        case resumeRecording = "com.chagok.recording.resume"

        var cfName: CFNotificationName {
            CFNotificationName(rawValue as CFString)
        }
    }

    /// Darwin Notification을 전송합니다.
    public static func post(_ name: Name) {
        CFNotificationCenterGetDarwinNotifyCenter()
            .post(name: name)
    }

    /// Darwin Notification을 구독합니다.
    /// 반환된 `DarwinNotificationObservation`을 유지해야 구독이 유지됩니다.
    /// 해제 시 자동으로 구독이 제거됩니다.
    public static func observe(_ name: Name, handler: @escaping @Sendable () -> Void) -> DarwinNotificationObservation {
        DarwinNotificationObservation(name: name, handler: handler)
    }
}

/// Darwin Notification 구독 관리 객체입니다.
/// deinit 시 자동으로 구독이 해제됩니다.
public final class DarwinNotificationObservation: @unchecked Sendable {
    private let name: DarwinNotificationCenter.Name
    private let handler: @Sendable () -> Void

    init(name: DarwinNotificationCenter.Name, handler: @escaping @Sendable () -> Void) {
        self.name = name
        self.handler = handler

        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = Unmanaged.passUnretained(self).toOpaque()

        CFNotificationCenterAddObserver(
            center,
            observer,
            { _, observer, _, _, _ in
                guard let observer else { return }
                let observation = Unmanaged<DarwinNotificationObservation>.fromOpaque(observer).takeUnretainedValue()
                observation.handler()
            },
            name.cfName.rawValue,
            nil,
            .deliverImmediately
        )
    }

    public func cancel() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterRemoveObserver(center, observer, name.cfName, nil)
    }

    deinit {
        cancel()
    }
}

// MARK: - CFNotificationCenter Extension

private extension CFNotificationCenter {
    func post(name: DarwinNotificationCenter.Name) {
        CFNotificationCenterPostNotification(
            self,
            name.cfName,
            nil,
            nil,
            true
        )
    }
}
