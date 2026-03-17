import Foundation

/// 녹음 시작 유스케이스 에러
public enum StartRecordingUseCaseError: LocalizedError, Sendable {
    case startFailed
    case cancelled
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .startFailed:
            return "녹음을 시작할 수 없습니다."
        case .cancelled:
            return nil
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    init(_ error: VoiceRecordStartRepositoryError) {
        switch error {
        case .startFailed:
            self = .startFailed
        case .cancelled:
            self = .cancelled
        case .unknown(let error):
            self = .unknown(error)
        }
    }
}
