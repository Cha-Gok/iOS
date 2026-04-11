import Foundation

public enum PlayVoiceRecordUseCaseError: LocalizedError, Sendable {
    case notPrepared
    case playFailed
    case unknown(any Error)

    public var errorDescription: String? {
        switch self {
        case .notPrepared:
            return "재생할 오디오가 준비되지 않았습니다."
        case .playFailed:
            return "오디오 재생을 시작할 수 없습니다."
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    init(_ error: VoiceRecordPlaybackRepositoryError) {
        switch error {
        case .notPrepared:
            self = .notPrepared
        case .playFailed:
            self = .playFailed
        case .prepareFailed, .pauseFailed, .seekFailed, .stopFailed, .unknown:
            self = .unknown(error)
        }
    }
}
