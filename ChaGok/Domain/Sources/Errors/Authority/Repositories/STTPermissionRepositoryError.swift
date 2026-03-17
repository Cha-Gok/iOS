import Foundation

/// STT 권한 리포지토리 에러
public enum STTPermissionRepositoryError: LocalizedError, Sendable {
    case cancelled
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .cancelled: return nil
        case .unknown(let error): return error.localizedDescription
        }
    }
}
