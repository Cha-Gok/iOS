import Foundation

/// 음성 메모 조회 유스케이스에서 발생할 수 있는 에러.
public enum ReadVoiceNoteUseCaseError: Error, LocalizedError, Sendable {

    /// 폴더별 목록 조회 실패.
    case fetchAllFailed(folderID: UUID)

    /// 해당 ID의 음성 메모를 찾을 수 없음.
    case recordNotFound(id: UUID)

    /// 단건 조회 실패.
    case fetchFailed(id: UUID)

    /// 알 수 없는 에러.
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .fetchAllFailed:
            return "음성 메모 목록 조회에 실패했습니다."
        case .recordNotFound:
            return "해당 음성 메모를 찾을 수 없습니다."
        case .fetchFailed:
            return "음성 메모 조회에 실패했습니다."
        case .unknown:
            return "알 수 없는 에러가 발생했습니다."
        }
    }
}
