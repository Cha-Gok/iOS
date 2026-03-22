import AVFoundation

extension AudioRecorderServiceError {
    init(_ error: Error) {
        let nsError = error as NSError
        guard let errorCode = AVAudioSession.ErrorCode(rawValue: nsError.code) else {
            self = .unknown(error)
            return
        }
        switch errorCode {
        case .insufficientPriority:
            self = .sessionActivationFailed
        case .mediaServicesFailed:
            self = .mediaServicesFailed
        default:
            self = .unknown(error)
        }
    }
}
