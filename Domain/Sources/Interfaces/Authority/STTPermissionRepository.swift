import Foundation

/// STT 권한과 관련된 기능을 제공하는 리포지토리 프로토콜.
public protocol STTPermissionRepository: Sendable {
    /// STT 권한이 허용되어 있는지 확인합니다.
    /// - Returns: 요청 결과 권한 상태.
    /// - Throws: `STTPermissionRepositoryError`
    func checkSTTPermission() async throws(STTPermissionRepositoryError) -> PermissionStatus

    /// STT 권한을 요청합니다.
    /// - Returns: 요청 결과 권한 상태.
    /// - Throws: `RequestSTTPermissionRepositoryError`
    func requestSTTPermission() async throws(STTPermissionRepositoryError) -> PermissionStatus
}
