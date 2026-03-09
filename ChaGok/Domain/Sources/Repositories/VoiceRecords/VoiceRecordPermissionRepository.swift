import Foundation

public protocol VoiceRecordPermissionRepository: Sendable {
    /// 녹음(마이크) 권한이 허용되어 있는지 확인합니다. 미허용 시 요청 후 거부되면 throw.
    /// - Throws: `VoiceRecordPermissionRepositoryError.permissionDenied`
    func checkRecordingPermission() async throws(VoiceRecordPermissionRepositoryError)
}
