@testable import Data
import Foundation
import XCTest

actor MockStorageService: StorageService {
    private var generateTempResult: Result<URL, StorageServiceError>?
    private var moveFileResult: Result<String, StorageServiceError>?
    private var saveResult: Result<String, StorageServiceError>?
    private var loadResult: Result<Data, StorageServiceError>?
    private var deleteResult: Result<Void, StorageServiceError>?
    private var existsResult: Bool = false

    private var generateTempCallCount = 0
    private var moveFileCallCount = 0
    private var saveCallCount = 0
    private var loadCallCount = 0
    private var deleteCallCount = 0
    private var existsCallCount = 0

    private var expectedGenerateTempCallCount: Int?
    private var expectedMoveFileCallCount: Int?
    private var expectedSaveCallCount: Int?
    private var expectedLoadCallCount: Int?
    private var expectedDeleteCallCount: Int?
    private var expectedExistsCallCount: Int?

    var movedSourceURL: URL?
    var movedDirectory: String?
    var movedFileName: String?
    var generatedTempFileName: String?

    func setGenerateTempResult(_ result: Result<URL, StorageServiceError>) {
        generateTempResult = result
    }

    func setMoveFileResult(_ result: Result<String, StorageServiceError>) {
        moveFileResult = result
    }

    func setSaveResult(_ result: Result<String, StorageServiceError>) {
        saveResult = result
    }

    func setLoadResult(_ result: Result<Data, StorageServiceError>) {
        loadResult = result
    }

    func setDeleteResult(_ result: Result<Void, StorageServiceError>) {
        deleteResult = result
    }

    func setExistsResult(_ result: Bool) {
        existsResult = result
    }

    func expectGenerateTemp(callCount: Int) {
        expectedGenerateTempCallCount = callCount
    }

    func expectMoveFile(callCount: Int) {
        expectedMoveFileCallCount = callCount
    }

    func expectSave(callCount: Int) {
        expectedSaveCallCount = callCount
    }

    func expectLoad(callCount: Int) {
        expectedLoadCallCount = callCount
    }

    func expectDelete(callCount: Int) {
        expectedDeleteCallCount = callCount
    }

    func expectExists(callCount: Int) {
        expectedExistsCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expectedGenerateTempCallCount {
            XCTAssertEqual(generateTempCallCount, expectedGenerateTempCallCount, file: file, line: line)
        }
        if let expectedMoveFileCallCount {
            XCTAssertEqual(moveFileCallCount, expectedMoveFileCallCount, file: file, line: line)
        }
        if let expectedSaveCallCount {
            XCTAssertEqual(saveCallCount, expectedSaveCallCount, file: file, line: line)
        }
        if let expectedLoadCallCount {
            XCTAssertEqual(loadCallCount, expectedLoadCallCount, file: file, line: line)
        }
        if let expectedDeleteCallCount {
            XCTAssertEqual(deleteCallCount, expectedDeleteCallCount, file: file, line: line)
        }
        if let expectedExistsCallCount {
            XCTAssertEqual(existsCallCount, expectedExistsCallCount, file: file, line: line)
        }
    }

    func generateTemporaryURL(fileName: String) async throws(StorageServiceError) -> URL {
        generateTempCallCount += 1
        generatedTempFileName = fileName
        guard let result = generateTempResult else {
            XCTFail("generateTempResult가 설정되지 않았습니다.")
            throw .uncreatableTemporaryPath
        }
        return try result.get()
    }

    func moveFile(
        from sourceURL: URL,
        toDirectory directory: String,
        fileName: String
    ) async throws(StorageServiceError) -> String {
        moveFileCallCount += 1
        movedSourceURL = sourceURL
        movedDirectory = directory
        movedFileName = fileName
        guard let result = moveFileResult else {
            XCTFail("moveFileResult가 설정되지 않았습니다.")
            throw .moveFailed
        }
        return try result.get()
    }

    func save(data: Data, toDirectory directory: String, fileName: String) async throws(StorageServiceError) -> String {
        saveCallCount += 1
        guard let result = saveResult else {
            XCTFail("saveResult가 설정되지 않았습니다.")
            throw .writeFailed
        }
        return try result.get()
    }

    func load(relativePath: String) async throws(StorageServiceError) -> Data {
        loadCallCount += 1
        guard let result = loadResult else {
            XCTFail("loadResult가 설정되지 않았습니다.")
            throw .readFailed
        }
        return try result.get()
    }

    func delete(fileURL: URL) async throws(StorageServiceError) {
        deleteCallCount += 1
        guard let result = deleteResult else {
            XCTFail("deleteResult가 설정되지 않았습니다.")
            throw .deleteFailed
        }
        _ = try result.get()
    }

    func exists(relativePath: String) async -> Bool {
        existsCallCount += 1
        return existsResult
    }

    nonisolated func absoluteURL(for relativePath: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(relativePath)
    }
}
