import Domain

/// 음성 인식(STT) 권한 상태를 확인하고 요청하는 서비스 프로토콜
public protocol STTPermissionService: Sendable {
    /// 현재 음성 인식 권한 상태를 확인합니다.
    /// - Returns: 현재 음성 인식 권한 상태
    func checkPermission() async -> PermissionStatus

    /// 사용자에게 음성 인식 권한을 요청합니다.
    /// - Returns: 권한 요청 후 음성 인식 권한 상태
    func requestPermission() async -> PermissionStatus
}
