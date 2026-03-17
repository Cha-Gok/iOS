import Foundation

/// 마이크 권한 확인 유스케이스 에러
public enum CheckMicrophonePermissionUseCaseError: LocalizedError, Sendable {
    case cancelled
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .cancelled: return nil
        case .unknown(let error): return error.localizedDescription
        }
    }
}
