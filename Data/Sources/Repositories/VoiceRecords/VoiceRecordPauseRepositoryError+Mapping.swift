import Domain

extension VoiceRecordPauseRepositoryError {
    init(_ error: AudioRecorderServiceError) {
        switch error {
        case .notRecording:
            self = .notRecording
        case .pauseFailed, .sessionActivationFailed, .mediaServicesFailed:
            self = .pauseFailed
        case .unknown(let underlying):
            self = .unknown(underlying)
        default:
            self = .unknown(error)
        }
    }
}
