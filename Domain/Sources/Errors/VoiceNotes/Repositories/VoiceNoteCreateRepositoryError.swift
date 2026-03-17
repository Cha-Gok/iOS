import Foundation

/// 음성 메모 생성 리포지토리에서 발생할 수 있는 에러 (ISP).
public enum VoiceNoteCreateRepositoryError: LocalizedError, Sendable {
    /// 음성 메모 생성 실패 (저장/디스크/권한 등).
    case createFailed
    /// 취소됨.
    case cancelled
    /// 예측할 수 없는 오류.
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .createFailed:
            return "음성 메모 생성에 실패했습니다."
        case .cancelled:
            return nil
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
