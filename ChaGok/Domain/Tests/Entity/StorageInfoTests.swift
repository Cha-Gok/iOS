import Foundation
import XCTest
@testable import Domain

final class StorageInfoTests: XCTestCase {

    // MARK: - usageRatio (R: Right, E: Error - division by zero)

    func test_usageRatio_totalBytes가0이면_0을반환한다() {
        let sut = StorageInfo(totalBytes: 0, freeBytes: 0, appUsedBytes: 0)
        XCTAssertEqual(sut.usageRatio, 0)
    }

    func test_usageRatio_정상값이면_앱사용량비율을반환한다() {
        let sut = StorageInfo(totalBytes: 100, freeBytes: 40, appUsedBytes: 20)
        XCTAssertEqual(sut.usageRatio, 0.2)
    }

    func test_usageRatio_appUsedBytes가totalBytes를넘어도_비율은1을초과할수있다() {
        let sut = StorageInfo(totalBytes: 100, freeBytes: 0, appUsedBytes: 150)
        XCTAssertEqual(sut.usageRatio, 1.5)
    }

    func test_usageRatio_Boundary_totalBytes가1일때() {
        let sut = StorageInfo(totalBytes: 1, freeBytes: 0, appUsedBytes: 1)
        XCTAssertEqual(sut.usageRatio, 1.0)
    }

    // MARK: - usedBytes (R, B, C)

    func test_usedBytes_totalMinusFree를반환한다() {
        let sut = StorageInfo(totalBytes: 100, freeBytes: 30, appUsedBytes: 10)
        XCTAssertEqual(sut.usedBytes, 70)
    }

    func test_usedBytes_freeBytes가totalBytes를넘으면_0을반환한다() {
        let sut = StorageInfo(totalBytes: 100, freeBytes: 120, appUsedBytes: 0)
        XCTAssertEqual(sut.usedBytes, 0)
    }

    func test_usedBytes_CrossCheck_수동계산과일치한다() {
        let sut = StorageInfo(totalBytes: 100, freeBytes: 30, appUsedBytes: 10)
        let expected = max(0, sut.totalBytes - sut.freeBytes)
        XCTAssertEqual(sut.usedBytes, expected)
    }

    func test_usedBytes_Inverse_usedBytes와freeBytes의합은totalBytes이다() {
        let sut = StorageInfo(totalBytes: 100, freeBytes: 30, appUsedBytes: 10)
        XCTAssertEqual(sut.usedBytes + sut.freeBytes, sut.totalBytes)
    }

    // MARK: - freeRatio (R, E, C)

    func test_freeRatio_totalBytes가0이면_0을반환한다() {
        let sut = StorageInfo(totalBytes: 0, freeBytes: 0, appUsedBytes: 0)
        XCTAssertEqual(sut.freeRatio, 0)
    }

    func test_freeRatio_정상값이면_freeBytes비율을반환한다() {
        let sut = StorageInfo(totalBytes: 100, freeBytes: 40, appUsedBytes: 20)
        XCTAssertEqual(sut.freeRatio, 0.4)
    }

    func test_freeRatio_CrossCheck_수동계산과일치한다() {
        let sut = StorageInfo(totalBytes: 100, freeBytes: 40, appUsedBytes: 20)
        let expected = Double(sut.freeBytes) / Double(sut.totalBytes)
        XCTAssertEqual(sut.freeRatio, expected)
    }

    func test_freeRatio_Inverse_totalBytes가양수일때_freeRatio와usedRatio의합은1이다() {
        let sut = StorageInfo(totalBytes: 100, freeBytes: 40, appUsedBytes: 20)
        let usedRatio = Double(sut.usedBytes) / Double(sut.totalBytes)
        XCTAssertEqual(sut.freeRatio + usedRatio, 1.0, accuracy: 0.0001)
    }

    // MARK: - isLowStorage (R, B)

    func test_isLowStorage_freeBytes가threshold미만이면_true() {
        let sut = StorageInfo(totalBytes: 1000, freeBytes: 50, appUsedBytes: 100)
        XCTAssertTrue(sut.isLowStorage(threshold: 100))
    }

    func test_isLowStorage_freeBytes가threshold와같으면_false() {
        let sut = StorageInfo(totalBytes: 1000, freeBytes: 100, appUsedBytes: 100)
        XCTAssertFalse(sut.isLowStorage(threshold: 100))
    }

    func test_isLowStorage_freeBytes가threshold초과면_false() {
        let sut = StorageInfo(totalBytes: 1000, freeBytes: 200, appUsedBytes: 100)
        XCTAssertFalse(sut.isLowStorage(threshold: 100))
    }

    func test_isLowStorage_Boundary_threshold가0일때_freeBytes가0이면_false() {
        let sut = StorageInfo(totalBytes: 100, freeBytes: 0, appUsedBytes: 100)
        XCTAssertFalse(sut.isLowStorage(threshold: 0))
    }

    func test_isLowStorage_Boundary_threshold가0일때_freeBytes가양수면_false() {
        let sut = StorageInfo(totalBytes: 100, freeBytes: 1, appUsedBytes: 50)
        XCTAssertFalse(sut.isLowStorage(threshold: 0))
    }
}
