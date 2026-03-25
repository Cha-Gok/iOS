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
}
