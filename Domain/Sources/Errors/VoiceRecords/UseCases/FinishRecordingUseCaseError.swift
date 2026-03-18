import Foundation

/// 녹음 종료 유스케이스 에러
public enum FinishRecordingUseCaseError: LocalizedError, Sendable {
    /// 진행 중인 녹음이 없는 상태에서 종료를 시도한 경우
    case notRecording
    /// 녹음 데이터 저장에 실패한 경우
    case finishFailed
    /// 오디오 인코딩 과정에서 에러가 발생한 경우
    case encodingFailed
    /// 사용자가 작업을 취소한 경우
    case cancelled
    /// 기타 알 수 없는 에러
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .notRecording:
            return "진행 중인 녹음이 없습니다."
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

    init(_ error: VoiceRecordFinishRepositoryError) {
        switch error {
        case .notRecording:
            self = .notRecording
        case .finishFailed:
            self = .finishFailed
        case .encodingFailed:
            self = .encodingFailed
        case .cancelled:
            self = .cancelled
        case .unknown(let error):
            self = .unknown(error)
        }
    }
}
