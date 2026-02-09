import Foundation
import XCTest
@testable import Domain

final class StorageRepositoryTests: XCTestCase {

    // MARK: - Interface (계약): 반환 타입 및 정상 동작

    func test_MockStorageRepository_fetchStorageInfo_StorageInfo를반환한다() async throws {
        let expected = StorageInfo(totalBytes: 2000, freeBytes: 800, appUsedBytes: 200)
        let mock = MockStorageRepository()
        mock.storageInfoResult = .success(expected)

        let result = try await mock.fetchStorageInfo()

        XCTAssertEqual(result.totalBytes, expected.totalBytes)
        XCTAssertEqual(result.freeBytes, expected.freeBytes)
        XCTAssertEqual(result.appUsedBytes, expected.appUsedBytes)
        XCTAssertEqual(mock.fetchStorageInfoCallCount, 1)
    }

    func test_MockStorageRepository_fetchRecordingFiles_RecordingFile배열을반환한다() async throws {
        let url = URL(fileURLWithPath: "/tmp/rec.m4a")
        let file = RecordingFile(
            id: UUID(),
            fileURL: url,
            createdAt: Date(),
            updatedAt: Date(),
            duration: 60,
            fileFormat: .m4a,
            fileSize: 1024,
            fileName: "rec.m4a",
            title: "T",
            description: "D",
            tags: []
        )
        let mock = MockStorageRepository()
        mock.recordingFilesResult = .success([file])

        let result = try await mock.fetchRecordingFiles()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, file.id)
        XCTAssertEqual(result[0].fileURL, url)
        XCTAssertEqual(mock.fetchRecordingFilesCallCount, 1)
    }

    func test_MockStorageRepository_deleteFiles_삭제된개수를반환한다() async throws {
        let mock = MockStorageRepository()
        mock.deleteFilesResult = .success(2)
        let ids = [UUID(), UUID()]

        let result = try await mock.deleteFiles(ids: ids)

        XCTAssertEqual(result, 2)
        XCTAssertEqual(mock.deleteFilesCallCount, 1)
        XCTAssertEqual(mock.deleteFilesReceivedIds, ids)
    }

    // MARK: - E: Error - 에러 전파

    func test_MockStorageRepository_fetchStorageInfo_에러시_throw한다() async {
        struct DummyError: Error {}
        let mock = MockStorageRepository()
        mock.storageInfoResult = .failure(DummyError())

        do {
            _ = try await mock.fetchStorageInfo()
            XCTFail("Should throw")
        } catch is DummyError {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_MockStorageRepository_fetchRecordingFiles_에러시_throw한다() async {
        struct DummyError: Error {}
        let mock = MockStorageRepository()
        mock.recordingFilesResult = .failure(DummyError())

        do {
            _ = try await mock.fetchRecordingFiles()
            XCTFail("Should throw")
        } catch is DummyError {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_MockStorageRepository_deleteFiles_에러시_throw한다() async {
        struct DummyError: Error {}
        let mock = MockStorageRepository()
        mock.deleteFilesResult = .failure(DummyError())

        do {
            _ = try await mock.deleteFiles(ids: [UUID()])
            XCTFail("Should throw")
        } catch is DummyError {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
