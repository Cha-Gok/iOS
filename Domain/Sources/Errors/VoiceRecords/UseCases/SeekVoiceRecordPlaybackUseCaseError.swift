import Foundation

public enum SeekVoiceRecordPlaybackUseCaseError: LocalizedError, Sendable {
    case notPrepared
    case seekFailed
    case cancelled
    case unknown(any Error)

    public var errorDescription: String? {
        switch self {
        case .notPrepared:
            return "재생할 오디오가 준비되지 않았습니다."
        case .seekFailed:
            return "오디오 위치를 이동할 수 없습니다."
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
        case .seekFailed:
            self = .seekFailed
        case .prepareFailed, .playFailed, .pauseFailed, .stopFailed:
            self = .unknown(error)
        case .cancelled:
            self = .cancelled
        case .unknown(let error):
            self = .unknown(error)
        }
    }
}
