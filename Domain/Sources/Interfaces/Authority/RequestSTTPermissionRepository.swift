import Foundation

/// STT 권한 요청을 담당하는 리포지토리 프로토콜.
public protocol RequestSTTPermissionRepository: Sendable {
    /// STT 권한을 요청합니다.
    /// - Returns: 요청 결과 권한 상태. 이미 거부된 경우 `.denied`를 반환합니다.
    /// - Throws: `RequestSTTPermissionRepositoryError`
    func requestSTTPermission() async throws(RequestSTTPermissionRepositoryError) -> PermissionStatus
}
