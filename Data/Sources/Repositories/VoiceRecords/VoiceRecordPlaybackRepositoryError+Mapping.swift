import Domain

extension VoiceRecordPlaybackRepositoryError {
    init(_ error: AudioPlaybackServiceError) {
        switch error {
        case .notPrepared:
            self = .notPrepared
        case .prepareFailed:
            self = .prepareFailed
        case .sessionActivationFailed, .mediaServicesFailed, .playFailed:
            self = .playFailed
        case .pauseFailed:
            self = .pauseFailed
        case .seekFailed:
            self = .seekFailed
        case .stopFailed:
            self = .stopFailed
        case .unknown(let underlying):
            self = .unknown(underlying)
        }
    }

    init(_ error: Error) {
        if let repositoryError = error as? VoiceRecordPlaybackRepositoryError {
            self = repositoryError
        } else if let serviceError = error as? AudioPlaybackServiceError {
            self = .init(serviceError)
        } else {
            self = .unknown(error)
        }
    }
}
