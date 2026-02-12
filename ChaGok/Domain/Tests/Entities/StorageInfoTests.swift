import XCTest
@testable import Domain

final class StorageInfoTests: XCTestCase {

    // MARK: - 2.1 init으로 생성한 값이 프로퍼티에 그대로 반영된다

    func test_초기화_값이_프로퍼티에_그대로_반영된다() {
        // Given
        let appUsedBytes: Int64 = 1_000_000
        let deviceTotalBytes: Int64 = 128_000_000_000
        let deviceUsedBytes: Int64 = 64_000_000_000

        // When
        let storageInfo = StorageInfo(
            appUsedBytes: appUsedBytes,
            deviceTotalBytes: deviceTotalBytes,
            deviceUsedBytes: deviceUsedBytes
        )

        // Then
        XCTAssertEqual(storageInfo.appUsedBytes, appUsedBytes)
        XCTAssertEqual(storageInfo.deviceTotalBytes, deviceTotalBytes)
        XCTAssertEqual(storageInfo.deviceUsedBytes, deviceUsedBytes)
    }

    // MARK: - 2.2 경계값으로 생성해도 크래시 없이 보관된다

    func test_경계값_초기화_시_정상_보관된다() {
        // Given & When & Then: 각 경계값 케이스 검증

        // 케이스 1: appUsedBytes == 0
        let zeroAppUsed = StorageInfo(
            appUsedBytes: 0,
            deviceTotalBytes: 100_000_000_000,
            deviceUsedBytes: 50_000_000_000
        )
        XCTAssertEqual(zeroAppUsed.appUsedBytes, 0)

        // 케이스 2: deviceUsedBytes == deviceTotalBytes (디스크 가득 참)
        let fullDisk = StorageInfo(
            appUsedBytes: 1_000_000,
            deviceTotalBytes: 128_000_000_000,
            deviceUsedBytes: 128_000_000_000
        )
        XCTAssertEqual(fullDisk.deviceUsedBytes, fullDisk.deviceTotalBytes)

        // 케이스 3: 매우 큰 값 (Int64 최대값 근처)
        let largeValue: Int64 = 9_000_000_000_000_000_000
        let largeStorageInfo = StorageInfo(
            appUsedBytes: largeValue,
            deviceTotalBytes: largeValue,
            deviceUsedBytes: largeValue
        )
        XCTAssertEqual(largeStorageInfo.appUsedBytes, largeValue)
        XCTAssertEqual(largeStorageInfo.deviceTotalBytes, largeValue)
        XCTAssertEqual(largeStorageInfo.deviceUsedBytes, largeValue)

        // 케이스 4: Int64 최대값
        let maxValue: Int64 = Int64.max
        let maxStorageInfo = StorageInfo(
            appUsedBytes: maxValue,
            deviceTotalBytes: maxValue,
            deviceUsedBytes: maxValue
        )
        XCTAssertEqual(maxStorageInfo.appUsedBytes, maxValue)
        XCTAssertEqual(maxStorageInfo.deviceTotalBytes, maxValue)
        XCTAssertEqual(maxStorageInfo.deviceUsedBytes, maxValue)
    }
}
