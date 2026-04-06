import Foundation

/// 녹음 취소 유스케이스 에러
public enum CancelRecordingUseCaseError: LocalizedError, Sendable {
    /// 사용자가 작업을 취소한 경우
    case cancelled
    /// 기타 알 수 없는 에러
    case unknown(Error)

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
