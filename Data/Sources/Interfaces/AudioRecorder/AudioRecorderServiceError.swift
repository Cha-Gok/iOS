import Foundation

/// 오디오 녹음 서비스 에러
public enum AudioRecorderServiceError: LocalizedError, Sendable {
    /// 이미 녹음이 진행 중인 경우
    case alreadyRecording
    /// 진행 중인 녹음이 없는 경우
    case notRecording
    /// 일시 정지된 녹음이 없는 경우
    case notPaused
    /// 다른 앱이 오디오 세션을 점유하여 활성화에 실패한 경우
    case sessionActivationFailed
    /// 미디어 서비스가 리셋되어 사용 불가한 경우
    case mediaServicesFailed
    /// 그 외 녹음 엔진 시작에 실패한 경우
    case startFailed
    /// 녹음 일시 정지에 실패한 경우
    case pauseFailed
    /// 녹음 재시작에 실패한 경우
    case resumeFailed
    /// 녹음 종료 및 저장에 실패한 경우
    case finishFailed
    /// 오디오 파일 인코딩에 실패한 경우
    case encodingFailed
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
        case .sessionActivationFailed:
            return "오디오 세션 활성화에 실패했습니다. 다른 오디오 앱 사용 중인지 확인해주세요."
        case .mediaServicesFailed:
            return "기기 미디어 서비스 상태에 문제가 있어 녹음을 할 수 없습니다."
        case .startFailed:
            return "녹음 엔진 시작에 실패했습니다."
        case .pauseFailed:
            return "녹음 일시 정지에 실패했습니다."
        case .resumeFailed:
            return "녹음 재시작에 실패했습니다."
        case .finishFailed:
            return "녹음 종료 및 저장에 실패했습니다."
        case .encodingFailed:
            return "오디오 파일 압축 및 변환에 실패했습니다."
        case .unknown(let error):
            return "알 수 없는 에러가 발생했습니다: \(error.localizedDescription)"
        }
    }
}
