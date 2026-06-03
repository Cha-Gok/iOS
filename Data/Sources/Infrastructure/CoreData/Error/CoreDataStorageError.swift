import Foundation

/// CoreDataLocalDataBase 초기화 단계에서 발생할 수 있는 에러.
public enum CoreDataStorageError: LocalizedError, Sendable {
    /// 모델 파일(.momd) 등 필수 리소스를 찾을 수 없음
    case resourceNotFound
    /// 영구 저장소(Persistent Store) 로드 및 초기화 실패
    case initializeFailed

    public var errorDescription: String? {
        switch self {
        case .resourceNotFound:
            return "모델 파일(.momd)을 찾을 수 없습니다."
        case .initializeFailed:
            return "영구 저장소(Persistent Store) 로드 및 초기화에 실패했습니다."
        }
    }
}
