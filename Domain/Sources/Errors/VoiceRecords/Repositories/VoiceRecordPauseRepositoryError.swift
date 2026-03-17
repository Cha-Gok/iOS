import Foundation

/// 녹음 일시정지 관련 리포지토리 에러
public enum VoiceRecordPauseRepositoryError: LocalizedError, Sendable {
    case notRecording
    case pauseFailed
    case cancelled
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .notRecording: return "진행 중인 녹음이 없습니다."
        case .pauseFailed: return "녹음 일시정지에 실패했습니다."
        case .cancelled: return nil
        case .unknown(let error): return error.localizedDescription
        }
    }
}
