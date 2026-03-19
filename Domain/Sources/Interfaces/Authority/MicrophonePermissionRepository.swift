import Foundation

/// 마이크 권한과 관련된 기능을 제공하는 리포지토리 프로토콜.
public protocol MicrophonePermissionRepository: Sendable {
    /// 마이크 권한이 허용되어 있는지 확인합니다.
    /// - Returns: 요청 결과 권한 상태.
    /// - Throws: `MicrophonePermissionRepositoryError`
    func checkMicrophonePermission() async throws(MicrophonePermissionRepositoryError) -> PermissionStatus

    /// 마이크 권한을 요청합니다.
    /// - Returns: 요청 결과 권한 상태.
    /// - Throws: `RequestMicrophonePermissionRepositoryError`
    func requestMicrophonePermission() async throws(MicrophonePermissionRepositoryError) -> PermissionStatus
}
