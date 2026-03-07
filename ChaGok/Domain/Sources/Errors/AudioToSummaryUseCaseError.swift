import Foundation

/// 오디오-요약 유스케이스에서 발생할 수 있는 에러.
public enum AudioToSummaryUseCaseError: LocalizedError, Sendable {

    /// 음성 인식(전사) 실패.
    case transcribeFailed(STTRepositoryError)

    /// 요약 생성 실패.
    case summarizeFailed(SummaryRepositoryError)

    /// 알 수 없는 에러.
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .transcribeFailed(let error):
            return error.errorDescription ?? "음성 인식에 실패했습니다."
        case .summarizeFailed(let error):
            return error.errorDescription ?? "요약 생성에 실패했습니다."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
