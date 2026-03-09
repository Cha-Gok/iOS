import Foundation

public enum FolderRepositoryError: LocalizedError, Sendable {
    /// 작업 취소의 경우
    case cancelled
    /// 폴더를 찾을 수 없는 경우 (조회, 수정, 삭제 시 발생)
    case notFound
    /// 동일한 이름의 폴더가 이미 존재하는 경우 (생성, 수정 시 발생)
    case duplicateName
    /// 폴더 생성이 실패한 경우
    case createFailed
    /// 폴더 조회가 실패한 경우
    case fetchFailed
    /// 폴더 업데이트가 실패한 경우
    case updateFailed
    /// 기타 알 수 없는 에러
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
            case .cancelled:
                nil
            case .notFound:
                "해당 폴더를 찾을 수 없습니다."
            case .duplicateName:
                "이미 동일한 이름의 폴더가 존재합니다."
            case .createFailed:
                "폴더 생성에 실패했습니다."
            case .fetchFailed:
                "폴더 목록을 불러오는데 실패했습니다."
            case .updateFailed:
                "폴더 정보를 수정하는데 실패했습니다."
            case .unknown(let error):
                error.localizedDescription
        }
    }
}
