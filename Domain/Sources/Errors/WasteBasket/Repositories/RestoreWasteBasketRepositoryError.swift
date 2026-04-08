import Foundation

public enum RestoreWasteBasketRepositoryError: LocalizedError, Sendable {
    /// 사용자가 작업을 취소한 경우
    case cancelled
    /// 복원 실패
    case restoreFailed(RestoreWasteBasketMethod)
    /// 알 수 없는 오류 (내부 에러 포함)
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .cancelled:
            return nil
        case .restoreFailed(let method):
            switch method {
            case .single:
                return "항목 복원에 실패했습니다."
            case .multiple:
                return "다수 항목 복원에 실패했습니다."
            }
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

public enum RestoreWasteBasketMethod: Equatable, Sendable {
    case single(item: WasteBasketItem)
    case multiple(items: [WasteBasketItem])
}
