import Speech

/// Speech 프레임워크 NSError → STTServiceError 변환
/// Interfaces 레이어에서 Speech framework import를 격리하기 위해 Infrastructure에 위치
extension STTServiceError {
    // SFSpeechRecognizerErrorDomain 에러 코드 상수
    // 출처: SFSpeechRecognizerError (Speech framework, iOS 10+)
    private enum SpeechErrorCode {
        static let cancelled = 301 // SFSpeechRecognizerError.Code.cancelled
        static let noRecognitionResult = 203 // kAFAssistantErrorDomain — 인식 결과 없음
        static let afAssistantDomain = "kAFAssistantErrorDomain"
    }

    init(_ error: Error) {
        let nsError = error as NSError
        if nsError.code == SpeechErrorCode.cancelled {
            self = .cancelled
        } else if nsError.domain == SpeechErrorCode.afAssistantDomain,
                  nsError.code == SpeechErrorCode.noRecognitionResult
        {
            self = .transcribeFailed
        } else {
            self = .unknown(error)
        }
    }
}
