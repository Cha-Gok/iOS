import Foundation

public enum ChaGokSystemError: Error {
    // rootDirectory를 찾을 수 없음
    case rootDirectoryNotFound
    // coreData model을 찾을 수 없음
    case initializeCoreDataFailed
    // 전체 용량이 부족한 경우
    case systemStorageIsFull
    // 알 수 없는 오류
    case unkownError
}
