import Domain

extension VoiceRecordResumeRepositoryError {
    init(_ error: AudioRecorderServiceError) {
        switch error {
        case .notPaused:
            self = .notPaused
        case .resumeFailed, .sessionActivationFailed, .mediaServicesFailed:
            self = .resumeFailed
        case .unknown(let underlying):
            self = .unknown(underlying)
        default:
            self = .unknown(error)
        }
    }
}
