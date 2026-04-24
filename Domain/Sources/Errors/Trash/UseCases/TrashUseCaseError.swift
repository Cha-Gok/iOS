import Foundation

public enum TrashUseCaseError: LocalizedError, Sendable {
    case fetchFailed
    case moveFailed
    case restoreFailed
    case deleteFailed
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "휴지통 정보를 불러오는데 실패했습니다."
        case .moveFailed:
            return "휴지통으로 이동하는데 실패했습니다."
        case .restoreFailed:
            return "복원하는데 실패했습니다."
        case .deleteFailed:
            return "영구 삭제하는데 실패했습니다."
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    init(_ error: VoiceNoteRepositoryError) {
        switch error {
        case .updateFailed:
            self = .moveFailed
        case .fetchFailed, .fetchAllFailed, .fetchRecentFailed:
            self = .fetchFailed
        default:
            self = .unknown(error)
        }
    }

    init(_ error: FolderRepositoryError) {
        switch error {
        case .updateFailed:
            self = .moveFailed
        case .fetchFailed, .notFound:
            self = .fetchFailed
        default:
            self = .unknown(error)
        }
    }
}
