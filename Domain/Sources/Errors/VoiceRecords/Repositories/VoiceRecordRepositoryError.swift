import Foundation

/// 녹음 및 마이크 권한 관련 리포지토리 에러
public enum VoiceRecordRepositoryError: LocalizedError, Sendable {
    /// 진행 중인 녹음이 없습니다
    case notRecording
    /// 이미 녹음이 진행 중입니다
    case alreadyRecording
    /// 일시 정지된 녹음이 없습니다
    case notPaused
    /// 녹음 시작에 실패했습니다
    case startFailed
    /// 녹음 일시 정지에 실패했습니다
    case pauseFailed
    /// 녹음 재개에 실패했습니다
    case resumeFailed
    /// 녹음 종료에 실패했습니다
    case finishFailed
    /// 오디오 인코딩에 실패했습니다
    case encodingFailed
    /// 사용자가 취소했습니다
    case cancelled
    /// 알 수 없는 에러
    case unknown(any Error)

    public var errorDescription: String? {
        switch self {
        case .notRecording:
            return "진행 중인 녹음이 없습니다."
        case .alreadyRecording:
            return "이미 녹음이 진행 중입니다."
        case .notPaused:
            return "일시 정지된 녹음이 없습니다."
        case .startFailed:
            return "녹음을 시작할 수 없습니다."
        case .pauseFailed:
            return "녹음 일시정지에 실패했습니다."
        case .resumeFailed:
            return "녹음 재시작에 실패했습니다."
        case .finishFailed:
            return "녹음 저장에 실패했습니다."
        case .encodingFailed:
            return "오디오 인코딩에 실패했습니다."
        case .cancelled:
            return nil
        case .unknown(let error):
            return "알 수 없는 에러가 발생했습니다: \(error.localizedDescription)"
        }
    }
}
