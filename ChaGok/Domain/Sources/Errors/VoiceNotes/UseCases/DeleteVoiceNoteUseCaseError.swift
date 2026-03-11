import Foundation

/// 음성 메모 삭제 유스케이스에서 발생할 수 있는 에러.
public enum DeleteVoiceNoteUseCaseError: LocalizedError, Sendable {

    /// 음성 메모 삭제 실패.
    case deleteFailed(id: UUID)

    /// 취소됨.
    case cancelled

    /// 예측할 수 없는 오류.
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .deleteFailed:
            return "음성 메모 삭제에 실패했습니다."
        case .cancelled:
            return nil
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
