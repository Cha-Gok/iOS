import Foundation

/// Core Data 스토리지 작업 중 발생할 수 있는 에러 정의
public enum CoreDataStorageError: LocalizedError, Sendable {
    /// 모델 파일(.momd) 등 필수 리소스를 찾을 수 없음
    case resourceNotFound
    /// 영구 저장소(Persistent Store) 로드 및 초기화 실패
    case initializeFailed
    /// 데이터 생성(Create) 실패
    case createFailed
    /// 데이터 조회(Fetch) 실패
    case fetchFailed
    /// 데이터 전체 조회(Fetch) 실패
    case fetchAllFailed
    /// 데이터 수정(Update) 실패
    case updateFailed
    /// 데이터 삭제(Delete) 실패
    case deleteFailed
    /// 관련 엔티티를 찾을 수 없음 (참조 무결성 실패)
    case relationNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .resourceNotFound:
            return "모델 파일(.momd)을 찾을 수 없습니다."
        case .initializeFailed:
            return "영구 저장소(Persistent Store) 로드 및 초기화에 실패했습니다."
        case .createFailed:
            return "데이터 생성에 실패했습니다."
        case .fetchFailed:
            return "데이터 조회에 실패했습니다."
        case .fetchAllFailed:
            return "전체 데이터 조회에 실패했습니다."
        case .updateFailed:
            return "데이터 수정에 실패했습니다."
        case .deleteFailed:
            return "데이터 삭제에 실패했습니다."
        case .relationNotFound(let entity):
            return "요청한 연관 데이터(\(entity))를 찾을 수 없습니다."
        }
    }
}
