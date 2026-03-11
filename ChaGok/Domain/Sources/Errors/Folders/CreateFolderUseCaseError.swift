import Foundation

public enum CreateFolderUseCaseError: LocalizedError, Sendable {
    /// 작업 취소의 경우
    case cancelled
    /// 유효하지 않은 이름의 경우
    case invalidName
    /// 동일한 이름의 폴더가 이미 존재하는 경우 (생성, 수정 시 발생)
    case duplicateName
    /// 폴더 생성이 실패한 경우
    case createFailed
    /// 기타 알 수 없는 에러
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
            case .cancelled:
                nil
            case .invalidName:
                "폴더 이름을 한 글자 이상 입력해 주세요."
            case .duplicateName:
                "이미 동일한 이름의 폴더가 존재합니다."
            case .createFailed:
                "폴더 생성에 실패했습니다."
            case .unknown(let error):
                error.localizedDescription
        }
    }

    public init(_ error: FolderRepositoryError) {
        switch error {
            case .cancelled:
                self = .cancelled
            case .duplicateName:
                self = .duplicateName
            case .createFailed:
                self = .createFailed
            default:
                self = .unknown(error)
        }
    }

}
