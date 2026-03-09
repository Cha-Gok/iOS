import Foundation

/// 마이크 권한 확인 유스케이스 에러
public enum CheckMicrophonePermissionUseCaseError: LocalizedError, Sendable {
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
