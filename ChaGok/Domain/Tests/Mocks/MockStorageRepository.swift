import Foundation
@testable import Domain

/// 테스트 전용 Mock. 동시 접근하지 않으므로 Sendable 요구를 @unchecked로 충족.
final class MockStorageRepository: StorageRepository, @unchecked Sendable {
    /// fetchStorageInfo() 호출 시 반환할 결과
    var storageInfoResult: Result<StorageInfo, Error> = .success(
        StorageInfo(
            appUsedBytes: 0,
            deviceTotalBytes: 0,
            deviceUsedBytes: 0
        )
    )

    /// fetchStorageInfo() 호출 횟수
    private(set) var fetchStorageInfoCallCount = 0

    func fetchStorageInfo() async throws -> StorageInfo {
        fetchStorageInfoCallCount += 1

        switch storageInfoResult {
        case .success(let storageInfo):
            return storageInfo
        case .failure(let error):
            throw error
        }
    }
}
