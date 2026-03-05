import Foundation

/// 음성 메모 삭제 유스케이스에서 발생할 수 있는 에러.
public enum DeleteVoiceNoteUseCaseError: Error, LocalizedError, Sendable {

    /// 음성 메모 삭제 실패.
    case deleteFailed(id: UUID)

    /// 알 수 없는 에러.
    case unknown

    public var errorDescription: String? {
        switch self {
        case .deleteFailed:
            return "음성 메모 삭제에 실패했습니다."
        case .unknown:
            return "알 수 없는 에러가 발생했습니다."
        }
    }
}
