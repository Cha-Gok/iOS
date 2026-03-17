import Foundation

/// 휴지통 이동 유스케이스에서 발생할 수 있는 오류들을 정의합니다.
public enum MoveWasteBasketUseCaseError: LocalizedError, Sendable {
    /// 사용자가 작업을 취소한 경우
    case cancelled
    /// 휴지통으로 이동 중 실패한 경우
    case moveFailed(MoveWasteBasketMethod)
    /// 알 수 없는 Error의 경우
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .cancelled:
            nil
        case .moveFailed(let method):
            switch method {
            case .single:
                "휴지통 개별 이동을 실패하였습니다"
            case .multiple:
                "휴지통 다수 선택 이동을 실패하였습니다"
            }
        case .unknown(let error):
            error.localizedDescription
        }
    }

    init(_ error: MoveWasteBasketRepositoryError) {
        switch error {
        case .cancelled:
            self = .cancelled
        case .moveFailed(let method):
            self = .moveFailed(method)
        case .unknown:
            self = .unknown(error)
        }
    }
}
