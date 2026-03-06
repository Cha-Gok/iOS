import Foundation

/// 음성 인식(STT) 리포지토리에서 발생할 수 있는 에러.
public enum STTRepositoryError: Error, LocalizedError, Sendable {

    /// 오디오 전사(Transcription) 실패.
    case transcribeFailed

    /// 알 수 없는 에러.
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .transcribeFailed:
            return "음성 인식에 실패했습니다."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
