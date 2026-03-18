import Foundation

/// 마이크 권한 요청 리포지토리 에러
public enum RequestMicrophonePermissionRepositoryError: LocalizedError, Sendable {
    case cancelled
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .cancelled:
            return nil
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
