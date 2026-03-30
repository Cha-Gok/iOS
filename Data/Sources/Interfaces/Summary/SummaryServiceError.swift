import Foundation

/// 요약 서비스에서 발생할 수 있는 에러.
public enum SummaryServiceError: Error, Sendable {
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
    case unknown(Error)
}
