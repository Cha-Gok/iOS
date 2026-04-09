import Foundation

public enum PrepareVoiceRecordPlaybackUseCaseError: LocalizedError, Sendable {
    case notPrepared
    case prepareFailed
    case cancelled
    case unknown(any Error)

    public var errorDescription: String? {
        switch self {
        case .notPrepared:
            return "재생할 오디오가 준비되지 않았습니다."
        case .prepareFailed:
            return "오디오 재생 준비에 실패했습니다."
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
        case .prepareFailed:
            self = .prepareFailed
        case .playFailed, .pauseFailed, .seekFailed, .stopFailed:
            self = .unknown(error)
        case .cancelled:
            self = .cancelled
        case .unknown(let error):
            self = .unknown(error)
        }
    }
}
