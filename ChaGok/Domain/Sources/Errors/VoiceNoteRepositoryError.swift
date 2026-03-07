import Foundation

/// 음성 메모 리포지토리에서 발생할 수 있는 에러.
public enum VoiceNoteRepositoryError: LocalizedError, Sendable {

    /// 음성 메모 생성 실패 (저장/디스크/권한 등).
    case createFailed

    /// 폴더별 목록 조회 실패.
    case fetchAllFailed(folderID: UUID)

    /// 해당 ID의 음성 메모를 찾을 수 없음.
    case recordNotFound(id: UUID)

    /// 단건 조회 실패.
    case fetchFailed(id: UUID)

    /// 음성 메모 업데이트 실패.
    case updateFailed

    /// 음성 메모 삭제 실패.
    case deleteFailed(id: UUID)

    /// 예측할 수 없는 오류 (알 수 없는 실패 시 사용).
    case unknown

    public var errorDescription: String? {
        switch self {
        case .createFailed:
            return "음성 메모 생성에 실패했습니다."
        case .fetchAllFailed:
            return "음성 메모 목록 조회에 실패했습니다."
        case .recordNotFound:
            return "해당 음성 메모를 찾을 수 없습니다."
        case .fetchFailed:
            return "음성 메모 조회에 실패했습니다."
        case .updateFailed:
            return "음성 메모 수정에 실패했습니다."
        case .deleteFailed:
            return "음성 메모 삭제에 실패했습니다."
        case .unknown:
            return "예기치 않은 오류가 발생했습니다."
        }
    }
}
