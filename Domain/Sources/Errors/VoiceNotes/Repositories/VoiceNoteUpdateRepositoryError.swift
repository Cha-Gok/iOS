import Foundation

/// 음성 메모 업데이트 리포지토리에서 발생할 수 있는 에러 (ISP).
public enum VoiceNoteUpdateRepositoryError: LocalizedError, Sendable {
    /// 음성 메모 업데이트 실패.
    case updateFailed
    /// 취소됨.
    case cancelled
    /// 예측할 수 없는 오류.
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .updateFailed:
            return "음성 메모 수정에 실패했습니다."
        case .cancelled:
            return nil
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
