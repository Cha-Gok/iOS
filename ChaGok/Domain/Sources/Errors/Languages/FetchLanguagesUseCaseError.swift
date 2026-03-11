import Foundation

public enum FetchLanguagesUseCaseError: LocalizedError, Sendable {
    /// 작업 취소의 경우
    case cancelled
    /// 설정된 언어를 찾을 수 없는 경우
    case notFound
    /// 알 수 없는 Error
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
            case .cancelled:
                nil
            case .notFound:
                "설정된 언어를 찾을 수 없습니다"
            case .unknown(let error):
                error.localizedDescription
        }
    }

    public init(_ error: FetchLanguagesRepositoryError) {
        switch error {
            case .cancelled:
                self = .cancelled
            case .notFound:
                self = .notFound
            case .unknown(let error):
                self = .unknown(error)
        }
    }
}
