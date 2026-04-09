import Foundation

public enum PauseVoiceRecordPlaybackUseCaseError: LocalizedError, Sendable {
    case notPrepared
    case pauseFailed
    case cancelled
    case unknown(any Error)

    public var errorDescription: String? {
        switch self {
        case .notPrepared:
            return "재생할 오디오가 준비되지 않았습니다."
        case .pauseFailed:
            return "오디오 재생을 일시정지할 수 없습니다."
        case .cancelled:
            return nil
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    init(_ error: VoiceRecordPlaybackRepositoryError) {
        switch error {
        case .notPrepared:
            self = .notPrepared
        case .pauseFailed:
            self = .pauseFailed
        case .prepareFailed, .playFailed, .seekFailed, .stopFailed:
            self = .unknown(error)
        case .cancelled:
            self = .cancelled
        case .unknown(let error):
            self = .unknown(error)
        }
    }
}
