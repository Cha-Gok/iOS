import Foundation

/// 재생 관련 통합 에러 타입.
/// 재생 준비, 재생, 일시정지, 탐색, 정지에서 발생할 수 있는 모든 에러 케이스를 포함합니다.
public enum PlaybackUseCaseError: LocalizedError, Sendable {
    /// 재생할 오디오가 준비되지 않은 경우
    case notPrepared
    /// 오디오 재생 준비에 실패한 경우
    case prepareFailed
    /// 오디오 재생을 시작할 수 없는 경우
    case playFailed
    /// 오디오 재생을 일시정지할 수 없는 경우
    case pauseFailed
    /// 오디오 위치를 이동할 수 없는 경우
    case seekFailed
    /// 오디오 재생을 중지할 수 없는 경우
    case stopFailed
    /// 알 수 없는 에러
    case unknown(any Error)

    public var errorDescription: String? {
        switch self {
        case .notPrepared:
            return "재생할 오디오가 준비되지 않았습니다."
        case .prepareFailed:
            return "오디오 재생 준비에 실패했습니다."
        case .playFailed:
            return "오디오 재생을 시작할 수 없습니다."
        case .pauseFailed:
            return "오디오 재생을 일시정지할 수 없습니다."
        case .seekFailed:
            return "오디오 위치를 이동할 수 없습니다."
        case .stopFailed:
            return "오디오 재생을 중지할 수 없습니다."
        case .unknown(let error):
            return "알 수 없는 에러가 발생했습니다: \(error.localizedDescription)"
        }
    }

    init(_ error: VoiceRecordPlaybackRepositoryError) {
        switch error {
        case .notPrepared:
            self = .notPrepared
        case .prepareFailed:
            self = .prepareFailed
        case .playFailed:
            self = .playFailed
        case .pauseFailed:
            self = .pauseFailed
        case .seekFailed:
            self = .seekFailed
        case .stopFailed:
            self = .stopFailed
        case .unknown(let innerError):
            self = .unknown(innerError)
        }
    }
}
