import Foundation

/// 음성 파일 전사 서비스 에러
public enum STTServiceError: LocalizedError, Sendable {
    /// Task 취소로 전사가 중단된 경우
    case cancelled
    /// 이미 전사가 진행 중인 경우
    case alreadyTranscribing
    /// SFSpeechRecognizer를 사용할 수 없는 경우 (언어 미지원, 기기 제한 등)
    case recognizerUnavailable
    /// 전사 중 오류 발생
    case transcribeFailed
    /// 알 수 없는 에러
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .cancelled:
            return nil
        case .alreadyTranscribing:
            return "이미 전사가 진행 중입니다."
        case .recognizerUnavailable:
            return "음성 인식기를 사용할 수 없습니다."
        case .transcribeFailed:
            return "음성 인식에 실패했습니다."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
