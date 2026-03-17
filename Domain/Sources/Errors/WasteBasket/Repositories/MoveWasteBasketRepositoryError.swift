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
            return nil
        case .moveFailed(let method):
            switch method {
            case .single:
                return "휴지통 개별 이동을 실패하였습니다"
            case .multiple:
                return "휴지통 다수 선택 이동을 실패하였습니다"
            }
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
