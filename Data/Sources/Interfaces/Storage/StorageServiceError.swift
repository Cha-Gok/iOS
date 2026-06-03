import Foundation

public enum StorageServiceError: LocalizedError, Sendable {
    case fileNotFound
    case uncreatableTemporaryPath
    case moveFailed
    case readFailed
    case writeFailed
    case deleteFailed
    case cancelled
    case unknown(any Error)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "파일을 찾을 수 없습니다."
        case .uncreatableTemporaryPath:
            return "임시 파일 경로를 생성할 수 없습니다."
        case .moveFailed:
            return "파일 이동 실패"
        case .readFailed:
            return "파일 읽기 실패"
        case .writeFailed:
            return "파일 저장 실패"
        case .deleteFailed:
            return "파일 삭제 실패"
        case .cancelled:
            return "작업이 취소되었습니다."
        case .unknown(let error):
            return "알 수 없는 에러가 발생했습니다: \(error.localizedDescription)"
        }
    }
}
