import Foundation

/// 오디오 녹음 서비스 에러
public enum AudioRecorderServiceError: LocalizedError, Sendable {
    /// 이미 녹음이 진행 중인 경우
    case alreadyRecording
    /// 다른 앱이 오디오 세션을 점유하여 활성화에 실패한 경우
    case sessionActivationFailed
    /// 미디어 서비스가 리셋되어 사용 불가한 경우
    case mediaServicesFailed
    /// 그 외 녹음 엔진 시작에 실패한 경우
    case startFailed
    /// 알 수 없는 에러
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "이미 녹음이 진행 중입니다."
        case .sessionActivationFailed:
            return "다른 앱이 오디오를 사용 중입니다."
        case .mediaServicesFailed:
            return "미디어 서비스를 사용할 수 없습니다."
        case .startFailed:
            return "녹음 엔진을 시작할 수 없습니다."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
