import Foundation

/// 녹음 재시작 관련 리포지토리 에러
public enum VoiceRecordResumeRepositoryError: LocalizedError, Sendable {
    case notPaused
    case resumeFailed
    case cancelled
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .notPaused: return "일시 정지된 녹음이 없습니다."
        case .resumeFailed: return "녹음 재시작에 실패했습니다."
        case .cancelled: return nil
        case .unknown(let error): return error.localizedDescription
        }
    }
}
