import Foundation

public enum FolderUseCaseError: LocalizedError, Sendable {
    /// 작업 취소의 경우
    case cancelled
    /// 유효하지 않은 이름의 경우
    case invalidName
    /// 유효하지 않은 글자 수의 경우
    case invalidLengthName
    /// 동일한 이름의 폴더가 이미 존재하는 경우
    case duplicateName
    /// 기본 폴더 등 사용할 수 없는 예약된 이름인 경우
    case reservedName
    /// 폴더를 찾을 수 없는 경우
    case notFound
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
            return nil
        case .invalidName:
            return "폴더 이름을 한 글자 이상 입력해 주세요."
        case .invalidLengthName:
            return "폴더 이름은 \(Policy.maxNameLength)자 이내로 입력해주세요."
        case .duplicateName:
            return "이미 동일한 이름의 폴더가 존재합니다."
        case .reservedName:
            return "해당 이름은 시스템 기능 전용이므로 사용할 수 없습니다."
        case .notFound:
            return "해당 폴더를 찾을 수 없습니다."
        case .createFailed:
            return "폴더 생성에 실패했습니다."
        case .fetchFailed:
            return "폴더 목록을 불러오는데 실패했습니다."
        case .updateFailed:
            return "폴더 정보를 수정하는데 실패했습니다."
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    init(_ error: FolderRepositoryError) {
        switch error {
        case .cancelled:
            self = .cancelled
        case .duplicateName:
            self = .duplicateName
        case .notFound:
            self = .notFound
        case .createFailed:
            self = .createFailed
        case .fetchFailed:
            self = .fetchFailed
        case .updateFailed:
            self = .updateFailed
        case .unknown(let e):
            self = .unknown(e)
        }
    }
}
