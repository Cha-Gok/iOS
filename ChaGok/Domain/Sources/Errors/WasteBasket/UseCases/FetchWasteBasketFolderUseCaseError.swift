import Foundation

/// 휴지통 폴더 조회 유스케이스에서 발생할 수 있는 오류들을 정의합니다.
public enum FetchWasteBasketFolderUseCaseError: LocalizedError, Sendable {
    /// 사용자가 작업을 취소한 경우
    case cancelled
    /// 휴지통 폴더 조회에 실패한 경우
    case fetchFailed
    /// 알 수 없는 Error의 경우
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
            case .cancelled:
                nil
            case .fetchFailed:
                "조회에 실패하였습니다"
            case .unknown(let error):
                error.localizedDescription
        }
    }

    init(_ error: FetchWasteBasketRepositoryError) {
        switch error {
            case .cancelled:
                self = .cancelled
            case .fetchFailed:
                self = .fetchFailed
            case .unknown(let error):
                self = .unknown(error)
        }
    }
}
