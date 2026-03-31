import Foundation

/// 요약 서비스에서 발생할 수 있는 에러.
public enum SummaryServiceError: LocalizedError, Sendable {
    /// 요약 생성 실패.
    case summarizeFailed
    /// 취소됨.
    case cancelled
    /// 보이스 모델이 준비되지 않음 (사용자 설정 등).
    case modelUnavailable
    /// 입력 또는 요청한 출력 언어가 모델에서 지원되지 않음.
    case unsupportedLanguage
    /// 모델 요청 빈도가 제한됨.
    case rateLimited
    /// 모델 응답이 비어 있거나 기대한 형식을 만족하지 않음.
    case invalidResponse
    /// 알 수 없는 에러.
    case unknown(any Error)

    public var errorDescription: String? {
        switch self {
        case .summarizeFailed:
            return "요약 생성에 실패했습니다."
        case .cancelled:
            return "요약 요청이 취소되었습니다."
        case .modelUnavailable:
            return "요약 모델이 준비되지 않았습니다. 모델 다운로드 상태를 확인해 주세요."
        case .unsupportedLanguage:
            return "지원되지 않는 언어입니다."
        case .rateLimited:
            return "너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해 주세요."
        case .invalidResponse:
            return "유효하지 않은 응답이 반환되었습니다."
        case .unknown(let error):
            return "알 수 없는 에러가 발생했습니다: \(error.localizedDescription)"
        }
    }
}
