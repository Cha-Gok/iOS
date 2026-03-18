import Foundation

/// 녹음 재개 유스케이스 에러
public enum ResumeRecordingUseCaseError: LocalizedError, Sendable {
    /// 일시정지된 녹음이 없는 상태에서 재개를 시도한 경우
    case notPaused
    /// 녹음 재개 작업에 실패한 경우
    case resumeFailed
    /// 사용자가 작업을 취소한 경우
    case cancelled
    /// 기타 알 수 없는 에러
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .notPaused:
            return "일시 정지된 녹음이 없습니다."
        case .resumeFailed:
            return "녹음 재시작에 실패했습니다."
        case .cancelled:
            return nil
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    init(_ error: VoiceRecordResumeRepositoryError) {
        switch error {
        case .notPaused:
            self = .notPaused
        case .resumeFailed:
            self = .resumeFailed
        case .cancelled:
            self = .cancelled
        case .unknown(let error):
            self = .unknown(error)
        }
    }
}
