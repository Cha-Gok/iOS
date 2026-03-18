import Foundation

/// 녹음 일시정지 관련 리포지토리 에러
public enum VoiceRecordPauseRepositoryError: LocalizedError, Sendable {
    /// 진행 중인 녹음이 없는 상태에서 일시정지를 시도한 경우
    case notRecording
    /// 녹음 일시정지 작업에 실패한 경우
    case pauseFailed
    /// 사용자가 작업을 취소한 경우
    case cancelled
    /// 기타 알 수 없는 에러
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .notRecording:
            return "진행 중인 녹음이 없습니다."
        case .pauseFailed:
            return "녹음 일시정지에 실패했습니다."
        case .cancelled:
            return nil
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
