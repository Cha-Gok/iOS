import Foundation

/// 녹음(VoiceRecord) 리포지토리에서 발생할 수 있는 에러.
public enum VoiceRecordRepositoryError: LocalizedError, Sendable {

    /// 녹음(마이크) 권한 거부.
    case permissionDenied

    /// 녹음 시작 실패.
    case startFailed

    /// 녹음이 진행 중이 아님 (일시정지/완료 시도 시).
    case notRecording

    /// 일시 정지된 상태가 아님 (재시작 시도 시).
    case notPaused

    /// 일시정지 처리 실패.
    case pauseFailed

    /// 재시작 처리 실패.
    case resumeFailed

    /// 녹음 완료·저장 실패.
    case finishFailed

    /// 인코딩 실패 (저장 과정).
    case encodingFailed

    /// 취소됨.
    case cancelled

    /// 예측할 수 없는 오류.
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "녹음 권한이 거부되었습니다."
        case .startFailed:
            return "녹음을 시작할 수 없습니다."
        case .notRecording:
            return "진행 중인 녹음이 없습니다."
        case .notPaused:
            return "일시 정지된 녹음이 없습니다."
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
            return error.localizedDescription
        }
    }
}
