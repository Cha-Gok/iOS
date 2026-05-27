import Foundation

public enum OnDeviceRepositoryError: LocalizedError, Sendable {
    /// Task 취소
    case cancelled
    /// 네트워크 연결 실패
    case networkFailed
    /// 모델 메모리 적재 실패
    case loadFailed
    /// unknown
    case unknown(Error)

    public var errorDescription: String {
        switch self {
        case .cancelled: return "작업이 취소되었습니다"
        case .networkFailed: return "네트워크 연결이 유실되었습니다"
        case .loadFailed: return "모델을 메모리에 올리지 못했습니다"
        case .unknown(let error): return "다운로드에 실패했습니다"
        }
    }

    public static func mapDownloadError(_ error: Error) -> Self {
        if isNetworkError(error) {
            return .networkFailed
        }

        return .unknown(error)
    }

    private static func isNetworkError(_ error: Error) -> Bool {
        let nsError = error as NSError

        if nsError.domain == NSURLErrorDomain {
            return true
        }

        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            return isNetworkError(underlying)
        }

        return false
    }
}
