import Foundation

public enum StopVoiceRecordPlaybackUseCaseError: LocalizedError, Sendable {
    case notPrepared
    case stopFailed
    case cancelled
    case unknown(any Error)

    public var errorDescription: String? {
        switch self {
        case .notPrepared:
            return "재생할 오디오가 준비되지 않았습니다."
        case .stopFailed:
            return "오디오 재생을 중지할 수 없습니다."
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
        case .stopFailed:
            self = .stopFailed
        case .prepareFailed, .playFailed, .pauseFailed, .seekFailed:
            self = .unknown(error)
        case .cancelled:
            self = .cancelled
        case .unknown(let error):
            self = .unknown(error)
        }
    }
}
