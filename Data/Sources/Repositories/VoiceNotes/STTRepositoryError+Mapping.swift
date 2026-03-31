import Domain

extension STTRepositoryError {
    init(_ error: STTServiceError) {
        switch error {
        case .cancelled:
            self = .cancelled
        case .alreadyTranscribing, .recognizerUnavailable, .transcribeFailed:
            self = .transcribeFailed
        case .unknown(let error):
            self = .unknown(error)
        }
    }
}
