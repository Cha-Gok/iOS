import Foundation

public enum StopVoiceRecordPlaybackUseCaseError: LocalizedError, Sendable {
    case notPrepared
    case stopFailed
    case unknown(any Error)

    public var errorDescription: String? {
        switch self {
        case .notPrepared:
            return "재생할 오디오가 준비되지 않았습니다."
        case .stopFailed:
            return "오디오 재생을 중지할 수 없습니다."
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
        case .prepareFailed, .playFailed, .pauseFailed, .seekFailed, .unknown:
            self = .unknown(error)
        }
    }
}
