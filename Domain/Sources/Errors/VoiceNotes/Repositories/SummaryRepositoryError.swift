import Foundation

/// 요약(Summary) 리포지토리에서 발생할 수 있는 에러.
public enum SummaryRepositoryError: LocalizedError, Sendable {
    /// 키워드·요약 생성 실패.
    case summarizeFailed

    /// 취소됨.
    case cancelled

    /// 알 수 없는 에러.
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .summarizeFailed:
            return "요약 생성에 실패했습니다."
        case .cancelled:
            return nil
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
