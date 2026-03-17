import Foundation

/// 오디오-요약 유스케이스에서 발생할 수 있는 에러.
public enum AudioToSummaryUseCaseError: LocalizedError, Sendable {
    /// 음성 인식(전사) 실패.
    case transcribeFailed(STTRepositoryError)
    /// 요약 생성 실패.
    case summarizeFailed(SummaryRepositoryError)
    /// 취소됨.
    case cancelled
    /// 알 수 없는 에러.
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .transcribeFailed(let error):
            return error.errorDescription ?? "음성 인식에 실패했습니다."
        case .summarizeFailed(let error):
            return error.errorDescription ?? "요약 생성에 실패했습니다."
        case .cancelled:
            return nil
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    init(_ error: Error) {
        if error is CancellationError {
            self = .cancelled
        } else if let error = error as? STTRepositoryError {
            switch error {
            case .cancelled:
                self = .cancelled
            case .transcribeFailed:
                self = .transcribeFailed(error)
            case .unknown(let error):
                self = .unknown(error)
            }
        } else if let error = error as? SummaryRepositoryError {
            switch error {
            case .cancelled:
                self = .cancelled
            case .summarizeFailed:
                self = .summarizeFailed(error)
            case .unknown(let error):
                self = .unknown(error)
            }
        } else {
            self = .unknown(error)
        }
    }
}
