import Foundation

public enum FetchRootUrlUseCaseError: LocalizedError, Sendable {
    /// 사용자가 작업을 취소한 경우
    case cancelled
    /// 알 수 없는 Error의 경우
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .cancelled:
            nil
        case .unknown(let error):
            error.localizedDescription
        }
    }

    init(_ error: WorkSpaceRootURLRepositoryError) {
        switch error {
        case .cancelled:
            self = .cancelled
        case .unknown(let error):
            self = .unknown(error)
        }
    }
}
