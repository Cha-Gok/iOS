import Domain

extension VoiceRecordFinishRepositoryError {
    init(_ error: AudioRecorderServiceError) {
        switch error {
        case .notRecording:
            self = .notRecording
        case .finishFailed:
            self = .finishFailed
        case .encodingFailed:
            self = .encodingFailed
        case .unknown(let underlying):
            self = .unknown(underlying)
        default:
            self = .unknown(error)
        }
    }
}
