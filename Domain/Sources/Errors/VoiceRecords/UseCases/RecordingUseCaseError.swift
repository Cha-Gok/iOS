import Foundation

/// 녹음 관련 통합 에러 타입.
/// 녹음 시작, 일시정지, 재개, 완료, 취소에서 발생할 수 있는 모든 에러 케이스를 포함합니다.
public enum RecordingUseCaseError: LocalizedError, Sendable {
    /// 이미 녹음이 진행 중인 경우
    case alreadyRecording
    /// 진행 중인 녹음이 없는 경우
    case notRecording
    /// 일시 정지된 녹음이 없는 경우
    case notPaused
    /// 녹음 시작에 실패한 경우
    case startFailed
    /// 녹음 일시 정지에 실패한 경우
    case pauseFailed
    /// 녹음 재개에 실패한 경우
    case resumeFailed
    /// 녹음 종료에 실패한 경우
    case finishFailed
    /// 오디오 인코딩에 실패한 경우
    case encodingFailed
    /// 사용자가 작업을 취소한 경우
    case cancelled
    /// 알 수 없는 에러
    case unknown(any Error)

    public var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "이미 녹음이 진행 중입니다."
        case .notRecording:
            return "진행 중인 녹음이 없습니다."
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
            return error.localizedDescription
        }
    }

    init(_ error: VoiceRecordRepositoryError) {
        switch error {
        case .alreadyRecording:
            self = .alreadyRecording
        case .notRecording:
            self = .notRecording
        case .notPaused:
            self = .notPaused
        case .startFailed:
            self = .startFailed
        case .pauseFailed:
            self = .pauseFailed
        case .resumeFailed:
            self = .resumeFailed
        case .finishFailed:
            self = .finishFailed
        case .encodingFailed:
            self = .encodingFailed
        case .cancelled:
            self = .cancelled
        case .unknown(let innerError):
            self = .unknown(innerError)
        }
    }
}
