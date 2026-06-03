import Foundation

/// WhisperKitl DataSource의 커스텀 에러 타입 정의
public enum WhisperDataSourceError: LocalizedError, Sendable {
    /// Task 취소
    case cancelled
    /// 네트워크 연결 실패
    case networkFailed
    /// 설치 경로를 찾지 못함
    case notFound
    /// load 실패 시
    case loadFailed
    /// 추천 모델이 없는 경우
    case notRecommendedModel
    /// unknown
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .cancelled: return "작업이 취소되었습니다"
        case .networkFailed: return "네트워크 연결이 유실되었습니다"
        case .notFound: return "설치 경로를 찾지 못합니다"
        case .loadFailed: return "Whisper로드 실패"
        case .notRecommendedModel: return "추천 모델이 없습니다"
        case .unknown(let error): return error.localizedDescription
        }
    }
}
