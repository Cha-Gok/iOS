import Foundation

/// 녹음 권한 관련 리포지토리 에러
public enum VoiceRecordPermissionRepositoryError: LocalizedError, Sendable {
    case permissionDenied
    case cancelled
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .permissionDenied: return "녹음 권한이 거부되었습니다."
        case .cancelled: return nil
        case .unknown(let error): return error.localizedDescription
        }
    }
}
