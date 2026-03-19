import Domain

extension VoiceRecordStartRepositoryError {
    init(_ error: AudioRecorderServiceError) {
        switch error {
        case .sessionActivationFailed, .mediaServicesFailed, .startFailed:
            self = .startFailed
        case .unknown(let underlying):
            self = .unknown(underlying)
        }
    }
}
