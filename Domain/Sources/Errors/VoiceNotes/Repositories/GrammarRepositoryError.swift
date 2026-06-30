import Foundation

/// 문법 교정(Grammar) 리포지토리에서 발생할 수 있는 에러.
public enum GrammarRepositoryError: LocalizedError, Sendable {
    /// 문법 교정 실패.
    case correctionFailed
    /// 취소됨.
    case cancelled
    /// 알 수 없는 에러.
    case unknown(any Error)

    public var errorDescription: String? {
        switch self {
        case .correctionFailed:
            return "문법 교정에 실패했습니다."
        case .cancelled:
            return nil
        case .unknown(let error):
            return "알 수 없는 에러가 발생했습니다: \(error.localizedDescription)"
        }
    }
}
