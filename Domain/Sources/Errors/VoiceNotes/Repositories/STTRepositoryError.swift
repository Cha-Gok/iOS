import Foundation

/// 음성 인식(STT) 리포지토리에서 발생할 수 있는 에러.
public enum STTRepositoryError: LocalizedError, Sendable {
    /// 오디오 전사(Transcription) 실패.
    case transcribeFailed
    /// 취소됨.
    case cancelled
    /// 알 수 없는 에러.
    case unknown(any Error)

    public var errorDescription: String? {
        switch self {
        case .transcribeFailed:
            return "음성 인식에 실패했습니다."
        case .cancelled:
            return nil
        case .unknown(let error):
            return "알 수 없는 에러가 발생했습니다: \(error.localizedDescription)"
        }
    }
}
