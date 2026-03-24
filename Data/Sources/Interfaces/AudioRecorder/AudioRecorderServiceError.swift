import Foundation

/// 오디오 녹음 서비스 에러
public enum AudioRecorderServiceError: Error, Sendable {
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
    case unknown(Error)
}
