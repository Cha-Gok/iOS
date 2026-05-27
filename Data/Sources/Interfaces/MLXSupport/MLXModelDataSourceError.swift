import Foundation

/// MLXModel DataSource의 커스텀 에러 타입 정의
public enum MLXModelDataSourceError: LocalizedError, Sendable {
    /// Task 취소
    case cancelled
    /// 네트워크 연결 실패
    case networkFailed
    /// 설치 경로를 찾지 못함
    case notFound
    /// unknown
    case unknown(Error)

    public var errorDescription: String {
        switch self {
        case .cancelled: return "작업이 취소되었습니다"
        case .networkFailed: return "네트워크 연결이 유실되었습니다"
        case .notFound: return "설치 경로를 찾지 못합니다"
        case .unknown(let error): return error.localizedDescription
        }
    }
}
