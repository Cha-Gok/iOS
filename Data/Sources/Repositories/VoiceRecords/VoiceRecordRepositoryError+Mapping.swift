import Domain

extension VoiceRecordRepositoryError {
    init(_ error: AudioRecorderServiceError) {
        switch error {
        case .notRecording:
            self = .notRecording
        case .alreadyRecording:
            self = .alreadyRecording
        case .notPaused:
            self = .notPaused
        case .startFailed, .sessionActivationFailed, .mediaServicesFailed:
            self = .startFailed
        case .pauseFailed:
            self = .pauseFailed
        case .resumeFailed:
            self = .resumeFailed
        case .finishFailed:
            self = .finishFailed
        case .encodingFailed:
            self = .encodingFailed
        case .unknown(let underlying):
            self = .unknown(underlying)
        }
    }

    init(_ error: StorageServiceError) {
        switch error {
        case .cancelled:
            self = .cancelled
        default:
            self = .finishFailed
        }
    }

    init(_ error: Error) {
        if let repositoryError = error as? VoiceRecordRepositoryError {
            self = repositoryError
        } else if let audioError = error as? AudioRecorderServiceError {
            self = .init(audioError)
        } else if let storageError = error as? StorageServiceError {
            self = .init(storageError)
        } else {
            self = .unknown(error)
        }
    }
}
