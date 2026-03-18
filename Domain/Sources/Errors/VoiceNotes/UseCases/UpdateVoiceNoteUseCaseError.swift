import Foundation

/// 음성 메모 업데이트 유스케이스에서 발생할 수 있는 에러.
public enum UpdateVoiceNoteUseCaseError: LocalizedError, Sendable {
    /// 음성 메모 제목이 유효하지 않음 (공백 등).
    case invalidTitle
    /// 음성 메모 제목 길이가 너무 김.
    case invalidLengthTitle
    /// 음성 메모 업데이트 실패.
    case updateFailed
    /// 취소됨.
    case cancelled
    /// 예측할 수 없는 오류.
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidTitle:
            return "음성 메모 제목을 입력해주세요."
        case .invalidLengthTitle:
            return "제목은 \(Policy.maxNameLength)자 이내로 입력해주세요."
        case .updateFailed:
            return "음성 메모 수정에 실패했습니다."
        case .cancelled:
            return nil
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    init(_ error: VoiceNoteUpdateRepositoryError) {
        switch error {
        case .updateFailed:
            self = .updateFailed
        case .cancelled:
            self = .cancelled
        case .unknown(let error):
            self = .unknown(error)
        }
    }
}
