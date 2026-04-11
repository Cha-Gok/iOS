import Foundation

public enum VoiceRecordPlaybackRepositoryError: LocalizedError, Sendable {
    case notPrepared
    case prepareFailed
    case playFailed
    case pauseFailed
    case seekFailed
    case stopFailed
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
}
