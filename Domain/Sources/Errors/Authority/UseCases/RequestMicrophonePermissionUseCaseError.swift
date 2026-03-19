import Foundation

/// 마이크 권한 요청 유스케이스 에러
public enum RequestMicrophonePermissionUseCaseError: LocalizedError, Sendable {
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

    init(_ error: MicrophonePermissionRepositoryError) {
        switch error {
        case .cancelled:
            self = .cancelled
        case .unknown(let error):
            self = .unknown(error)
        }
    }
}
