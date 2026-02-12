import Foundation
@testable import Domain

/// 테스트 전용 Mock.
actor MockStorageRepository: StorageRepository {
    /// fetchStorageInfo() 호출 시 반환할 결과
    var storageInfoResult: Result<StorageInfo, Error> = .success(
        StorageInfo(
            appUsedBytes: 0,
            deviceTotalBytes: 0,
            deviceUsedBytes: 0
        )
    )

    /// fetchStorageInfo() 호출 횟수
    var fetchStorageInfoCallCount = 0

    func putStorageInfo(_ result: Result<StorageInfo, Error>) {
        storageInfoResult = result
    }

    func fetchStorageInfo() throws -> StorageInfo {
        fetchStorageInfoCallCount += 1

        return try storageInfoResult.get()
    }
}
