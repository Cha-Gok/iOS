import Foundation

/// 마이크 권한 확인/요청 통합 에러 타입.
public enum MicrophonePermissionUseCaseError: LocalizedError, Sendable {
    /// 사용자가 작업을 취소한 경우
    case cancelled
    /// 알 수 없는 에러
    case unknown(any Error)

    public var errorDescription: String? {
        switch self {
        case .cancelled:
            return nil
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    init(_ error: VoiceRecordRepositoryError) {
        switch error {
        case .cancelled:
            self = .cancelled
        default:
            self = .unknown(error)
        }
    }
}
