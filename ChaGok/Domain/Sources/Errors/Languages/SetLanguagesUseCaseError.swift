import Foundation

public enum SetLanguagesUseCaseError: LocalizedError, Sendable {
    /// 작업 취소의 경우
    case cancelled
    /// 언어 설정 저장에 실패한 경우
    case saveFailed
    /// 알 수 없는 Error
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
            case .cancelled:
                nil
            case .saveFailed:
                "언어 설정 저장에 실패했습니다"
            case .unknown(let error):
                error.localizedDescription
        }
    }
}
