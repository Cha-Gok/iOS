import Foundation

public protocol MicrophonePermissionRepository: Sendable {
    /// 마이크 권한이 허용되어 있는지 확인합니다.
    /// - Throws: `VoiceRecordPermissionRepositoryError`
    func checkMicrophonePermission() async throws(MicrophonePermissionRepositoryError)
        -> PermissionStatus
}
