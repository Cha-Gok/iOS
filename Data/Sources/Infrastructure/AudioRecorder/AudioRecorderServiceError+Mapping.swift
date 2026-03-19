import AVFoundation

extension AudioRecorderServiceError {
    init(_ error: Error) {
        let nsError = error as NSError
        switch nsError.code {
        case AVAudioSession.ErrorCode.insufficientPriority.rawValue:
            self = .sessionActivationFailed
        case AVAudioSession.ErrorCode.mediaServicesFailed.rawValue:
            self = .mediaServicesFailed
        default:
            self = .unknown(error)
        }
    }
}
