import Foundation

/// 녹음 시작 유스케이스 에러
public enum StartRecordingUseCaseError: LocalizedError, Sendable {
    case permissionDenied
    case startFailed
    case cancelled
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .permissionDenied: return "녹음 권한이 거부되었습니다."
        case .startFailed: return "녹음을 시작할 수 없습니다."
        case .cancelled: return nil
        case .unknown(let error): return error.localizedDescription
        }
    }
}
