import Foundation

/// 음성 메모 유스케이스(Create/Read/Update/Delete)에서 발생할 수 있는 에러.
public enum VoiceNoteUseCaseError: LocalizedError, Sendable {

    /// 검증 실패: 녹음 길이가 유효하지 않음 (0 미만).
    case invalidDuration(duration: Double)

    /// 검증 실패: 오디오 파일 경로가 유효하지 않음 (file URL이 아니거나 path가 비어 있음).
    case invalidAudioFilePath(URL)

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

    /// 예측할 수 없는 오류.
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidDuration:
            return "녹음 길이가 올바르지 않습니다."
        case .invalidAudioFilePath:
            return "오디오 파일 경로가 올바르지 않습니다."
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
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
