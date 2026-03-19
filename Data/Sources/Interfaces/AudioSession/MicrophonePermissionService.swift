import Domain

/// 마이크 권한 상태를 확인하고 요청하는 서비스 프로토콜
protocol MicrophonePermissionService: Sendable {
    /// 현재 마이크 권한 상태를 확인합니다.
    /// - Returns: 현재 마이크 권한 상태
    func checkPermission() async -> PermissionStatus

    /// 사용자에게 마이크 권한을 요청합니다.
    /// - Returns: 권한 요청 후 마이크 권한 상태
    func requestPermission() async -> PermissionStatus
}
