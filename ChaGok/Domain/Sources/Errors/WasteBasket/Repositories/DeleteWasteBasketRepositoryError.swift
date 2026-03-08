import Foundation

public enum DeleteWasteBasketRepositoryError: LocalizedError, Sendable {
    /// 사용자가 작업을 취소한 경우
    case cancelled
    /// 삭제하려는 항목을 찾을 수 없는 경우
    case deleteFailed(DeleteWasteBasketMethod)
    /// 알 수 없는 오류 (내부 에러 포함)
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .cancelled:
            nil
        case .deleteFailed(let method):
            method.errorDescription
        case .unknown(let error):
            error.localizedDescription
        }
    }
}
