import Foundation

/// 녹음 시작 유스케이스 에러
public enum StartRecordingUseCaseError: LocalizedError, Sendable {
    /// 이미 녹음이 진행 중인 경우
    case alreadyRecording
    /// 녹음 시작 작업에 실패한 경우
    case startFailed
    /// 사용자가 작업을 취소한 경우
    case cancelled
    /// 기타 알 수 없는 에러
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "이미 녹음이 진행 중입니다."
        case .startFailed:
            return "녹음을 시작할 수 없습니다."
        case .cancelled:
            return nil
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    init(_ error: VoiceRecordRepositoryError) {
        switch error {
        case .alreadyRecording:
            self = .alreadyRecording
        case .startFailed:
            self = .startFailed
        case .cancelled:
            self = .cancelled
        case .unknown(let innerError):
            self = .unknown(innerError)
        default:
            self = .unknown(error)
        }
    }
}
