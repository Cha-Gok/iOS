import Domain

extension VoiceRecordStartRepositoryError {
    init(_ error: AudioRecorderServiceError) {
        switch error {
        case .alreadyRecording:
            self = .alreadyRecording
        case .sessionActivationFailed, .mediaServicesFailed, .startFailed:
            self = .startFailed
        case .unknown(let underlying):
            self = .unknown(underlying)
        default:
            self = .unknown(error)
        }
    }
}
