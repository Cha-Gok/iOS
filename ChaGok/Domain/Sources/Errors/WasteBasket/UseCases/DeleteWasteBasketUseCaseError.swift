import Foundation

/// 휴지통 삭제 유스케이스에서 발생할 수 있는 오류들을 정의합니다.
public enum DeleteWasteBasketUseCaseError: LocalizedError, Sendable {
    /// 사용자가 작업을 취소한 경우
    case cancelled
    /// 삭제하려는 항목을 찾을 수 없는 경우
    case deleteFailed(DeleteWasteBasketMethod)
    /// 알 수 없는 에러 (내부 에러 포함)
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

    init(_ error: DeleteWasteBasketRepositoryError) {
        switch error {
            case .cancelled:
                self = .cancelled
            case .deleteFailed(let method):
                self = .deleteFailed(method)
            case .unknown(let error):
                self = .unknown(error)
        }
    }
}
