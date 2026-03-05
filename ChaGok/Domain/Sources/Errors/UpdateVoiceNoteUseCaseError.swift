import Foundation

/// 음성 메모 업데이트 유스케이스에서 발생할 수 있는 에러.
public enum UpdateVoiceNoteUseCaseError: Error, LocalizedError, Sendable {

    /// 음성 메모 업데이트 실패.
    case updateFailed

    /// 알 수 없는 에러.
    case unknown

    public var errorDescription: String? {
        switch self {
        case .updateFailed:
            return "음성 메모 수정에 실패했습니다."
        case .unknown:
            return "알 수 없는 에러가 발생했습니다."
        }
    }
}
