import Foundation

/// 녹음 종료 유스케이스 에러
public enum FinishRecordingUseCaseError: LocalizedError, Sendable {
    case notRecording
    case finishFailed
    case encodingFailed
    case cancelled
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .notRecording: return "진행 중인 녹음이 없습니다."
        case .finishFailed: return "녹음 저장에 실패했습니다."
        case .encodingFailed: return "오디오 인코딩에 실패했습니다."
        case .cancelled: return nil
        case .unknown(let error): return error.localizedDescription
        }
    }
}
