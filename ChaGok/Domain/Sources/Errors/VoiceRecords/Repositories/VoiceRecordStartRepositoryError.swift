import Foundation

/// 녹음 시작 관련 리포지토리 에러
public enum VoiceRecordStartRepositoryError: LocalizedError, Sendable {
    case startFailed
    case cancelled
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .startFailed: return "녹음을 시작할 수 없습니다."
        case .cancelled: return nil
        case .unknown(let error): return error.localizedDescription
        }
    }
}
