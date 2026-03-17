import Foundation

public protocol STTPermissionRepository: Sendable {
    /// STT 권한이 허용되어 있는지 확인합니다.
    /// - Throws: `STTPermissionRepositoryError`
    func checkSTTPermission() async throws(STTPermissionRepositoryError) -> PermissionStatus
}
