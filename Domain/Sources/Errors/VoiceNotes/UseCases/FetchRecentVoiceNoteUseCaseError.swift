import Foundation

/// 최근 기록 VoiceNote 조회 유스케이스에서 발생할 수 있는 에러.
public enum FetchRecentVoiceNoteUseCaseError: LocalizedError, Sendable {
    /// 취소됨.
    case cancelled
    /// 조회 실패.
    case fetchFailed
    /// 예측할 수 없는 오류.
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .cancelled:
            return nil
        case .fetchFailed:
            return "최근 기록 조회에 실패했습니다."
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    init(_ error: VoiceNoteFetchRepositoryError) {
        switch error {
        case .cancelled:
            self = .cancelled
        case .fetchRecentFailed, .fetchAllFailed, .fetchFailed, .defaultFolderNotFound, .recordNotFound:
            self = .fetchFailed
        case .unknown(let error):
            self = .unknown(error)
        }
    }
}
