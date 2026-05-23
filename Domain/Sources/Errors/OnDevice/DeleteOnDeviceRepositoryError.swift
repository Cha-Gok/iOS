import Foundation

public enum DeleteOnDeviceRepositoryError: LocalizedError, Sendable {
    /// Task 취소
    case cancelled
    case deleteWhisperFailed
    case deleteMLXFailed
    case unknown(Error)

    public var errorDescription: String {
        switch self {
        case .cancelled:
            return "취소되었습니다"
        case .deleteWhisperFailed:
            return "whisper 모델 삭제를 실패하였습니다"
        case .deleteMLXFailed:
            return "MLX 모델 삭제를 실패하였습니다"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
