import Foundation

/// 휴지통 복원 유스케이스에서 발생할 수 있는 오류들을 정의합니다.
public enum RestoreWasteBasketUseCaseError: LocalizedError, Sendable {
    /// 사용자가 작업을 취소한 경우
    case cancelled
    /// 복원 실패
    case restoreFailed(RestoreWasteBasketMethod)
    /// 알 수 없는 에러 (내부 에러 포함)
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

    init(_ error: RestoreWasteBasketRepositoryError) {
        switch error {
        case .cancelled:
            self = .cancelled
        case .restoreFailed(let method):
            self = .restoreFailed(method)
        case .unknown(let error):
            self = .unknown(error)
        }
    }
}
