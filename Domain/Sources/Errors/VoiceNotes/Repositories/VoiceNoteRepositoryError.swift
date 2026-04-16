import Foundation

/// 음성 메모 리포지토리 통합 에러.
public enum VoiceNoteRepositoryError: LocalizedError, Sendable {
    case createFailed
    case updateFailed
    case fetchFailed(id: UUID?)
    case fetchAllFailed(folderID: UUID?)
    case fetchRecentFailed
    case recordNotFound(id: UUID)
    case defaultFolderNotFound
    case cancelled
    case unknown(Error)

    public init(_ error: Error) {
        if let repoError = error as? VoiceNoteRepositoryError {
            self = repoError
        } else if (error as NSError).domain == NSURLErrorDomain, (error as NSError).code == NSURLErrorCancelled {
            self = .cancelled
        } else {
            self = .unknown(error)
        }
    }

    public var errorDescription: String? {
        switch self {
        case .createFailed:
            return "음성 메모 생성에 실패했습니다."
        case .updateFailed:
            return "음성 메모 수정에 실패했습니다."
        case .fetchFailed:
            return "음성 메모 조회에 실패했습니다."
        case .fetchAllFailed:
            return "음성 메모 목록 조회에 실패했습니다."
        case .fetchRecentFailed:
            return "최근 기록 조회에 실패했습니다."
        case .recordNotFound:
            return "해당 음성 메모를 찾을 수 없습니다."
        case .defaultFolderNotFound:
            return "기본 폴더를 찾을 수 없습니다."
        case .cancelled:
            return nil
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
