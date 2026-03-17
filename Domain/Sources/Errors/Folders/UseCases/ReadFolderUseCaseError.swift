import Foundation

public enum ReadFolderUseCaseError: LocalizedError, Sendable {
    /// 작업 취소의 경우
    case cancelled
    /// 폴더를 찾을 수 없는 경우 (조회, 수정 시 발생)
    case notFound
    /// 폴더 조회가 실패한 경우
    case fetchFailed
    /// 기타 알 수 없는 에러
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .cancelled:
            return nil
        case .notFound:
            return "해당 폴더를 찾을 수 없습니다."
        case .fetchFailed:
            return "폴더 목록을 불러오는데 실패했습니다."
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    init(_ error: FolderRepositoryError) {
        switch error {
        case .cancelled:
            self = .cancelled
        case .notFound:
            self = .notFound
        case .fetchFailed:
            self = .fetchFailed
        default:
            self = .unknown(error)
        }
    }
}
