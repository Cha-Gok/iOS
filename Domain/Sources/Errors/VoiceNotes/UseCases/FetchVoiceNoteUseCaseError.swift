import Foundation

/// 음성 메모 조회 유스케이스에서 발생할 수 있는 에러.
public enum FetchVoiceNoteUseCaseError: LocalizedError, Sendable {
    /// 폴더별 목록 조회 실패.
    case fetchAllFailed(folderID: UUID)
    /// 해당 ID의 음성 메모를 찾을 수 없음.
    case recordNotFound(id: UUID)
    /// 단건 조회 실패.
    case fetchFailed(id: UUID)
    /// 취소됨.
    case cancelled
    /// 예측할 수 없는 오류.
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .fetchAllFailed:
            return "음성 메모 목록 조회에 실패했습니다."
        case .recordNotFound:
            return "해당 음성 메모를 찾을 수 없습니다."
        case .fetchFailed:
            return "음성 메모 조회에 실패했습니다."
        case .cancelled:
            return nil
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    init(_ error: VoiceNoteFetchRepositoryError) {
        switch error {
        case .fetchAllFailed(let folderID):
            self = .fetchAllFailed(folderID: folderID)
        case .recordNotFound(let id):
            self = .recordNotFound(id: id)
        case .fetchFailed(let id):
            self = .fetchFailed(id: id)
        case .cancelled:
            self = .cancelled
        case .unknown(let error):
            self = .unknown(error)
        }
    }
}
