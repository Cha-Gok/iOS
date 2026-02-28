import Foundation

/// 폴더 관련 작업 중 발생할 수 있는 에러 정의
public enum FolderError: LocalizedError {
    /// 중복된 이름의 폴더가 이미 존재함
    case duplicateName
    /// 대상 폴더를 찾을 수 없음
    case notFound
    /// 폴더 생성 실패
    case createFailed
    /// 폴더 목록 또는 정보 읽기 실패
    case readFailed
    /// 폴더 정보 수정 실패
    case updateFailed
    /// 폴더 삭제 실패
    case deleteFailed
    /// 기타 정의되지 않은 에러
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .duplicateName: return "이미 같은 이름의 폴더가 존재합니다."
        case .notFound: return "해당 폴더를 찾을 수 없습니다."
        case .createFailed: return "폴더 생성에 실패했습니다."
        case .readFailed: return "폴더 정보를 읽어오는데 실패했습니다."
        case .updateFailed: return "폴더 수정에 실패했습니다."
        case .deleteFailed: return "폴더 삭제에 실패했습니다."
        case .unknown(let error): return error.localizedDescription
        }
    }
}
