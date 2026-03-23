import Foundation

/// Core Data 스토리지 작업 중 발생할 수 있는 에러 정의
public enum CoreDataStorageError: Error, Sendable {
    /// 모델 파일(.momd) 등 필수 리소스를 찾을 수 없음
    case resourceNotFound
    /// 영구 저장소(Persistent Store) 로드 및 초기화 실패
    case initializeFailed
    /// 정의되지 않은 기타 에러
    case unknown(any Error)
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
}
