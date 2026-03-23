import Domain

extension STTRepositoryError {
    init(_ error: STTServiceError) {
        switch error {
        case .cancelled:
            self = .cancelled
        case .alreadyTranscribing:
            self = .transcribeFailed
        case .recognizerUnavailable:
            self = .transcribeFailed
        case .transcribeFailed:
            self = .transcribeFailed
        case .unknown(let e):
            self = .unknown(e)
        }
    }
}
