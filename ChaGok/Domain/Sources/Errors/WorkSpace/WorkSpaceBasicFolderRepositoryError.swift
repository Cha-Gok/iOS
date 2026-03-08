import Foundation

public enum WorkSpaceBasicFolderRepositoryError: LocalizedError, Sendable {
    /// 사용자가 작업을 취소한 경우
    case cancelled
    /// 기본 폴더를 찾을 수 없는 경우
    case notFound
    /// 기본 폴더를 생성 할 수 없는 경우
    case createFailed
    /// 알 수 없는 Error의 경우
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
            case .cancelled:
                nil
            case .notFound:
                "기본 폴더를 찾을 수 없습니다"
            case .createFailed:
                "기본 폴더를 생성 할 수 없습니다"
            case .unknown(let error):
                error.localizedDescription
        }
    }
}
