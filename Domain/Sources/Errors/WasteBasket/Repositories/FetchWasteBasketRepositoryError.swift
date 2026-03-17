import Foundation

public enum FetchWasteBasketRepositoryError: LocalizedError, Sendable {
    /// 사용자가 작업을 취소한 경우
    case cancelled
    /// 조회 실패의 경우
    case fetchFailed
    /// 알 수 없는 오류 (내부 에러 포함)
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .cancelled:
            nil
        case .fetchFailed:
            "데이터 조회에 실패했습니다."
        case .unknown(let error):
            error.localizedDescription
        }
    }
}
