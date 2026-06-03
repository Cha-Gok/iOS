import Foundation

public enum AvailableModelSupportRepositoryError: LocalizedError, Sendable {
    /// Task 취소
    case cancelled
    /// 모델을 찾을 수 없음
    case notFoundModel
    /// unknown
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .cancelled: return nil
        case .notFoundModel: return "설치 가능한 모델이 없습니다"
        case .unknown(let error): return error.localizedDescription
        }
    }
}
