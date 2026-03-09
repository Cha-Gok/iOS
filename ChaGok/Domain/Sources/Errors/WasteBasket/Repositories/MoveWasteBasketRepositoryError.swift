import Foundation

public enum MoveWasteBasketRepositoryError: LocalizedError, Sendable {
    /// 사용자가 작업을 취소한 경우
    case cancelled
    /// 휴지통으로 이동 중 실패
    case moveFailed(MoveWasteBasketMethod)
    /// 알 수 없는 오류 (내부 에러 포함)
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .cancelled:
            nil
        case .moveFailed(let method):
            method.errorDescription
        case .unknown(let error):
            error.localizedDescription
        }
    }
}
