@testable import Data
import Domain
import XCTest

actor MockFolderLocalDataBase: LocalDataBase {
    typealias Domain = Folder

    private var createResult: Result<Folder, Error>?
    private var fetchResult: Result<[Folder], Error>?
    private var updateResult: Result<Folder, Error>?
    private var deleteResult: Result<Folder, Error>?

    private var actualCreateCallCount = 0
    private var actualFetchCallCount = 0
    private var actualUpdateCallCount = 0
    private var actualDeleteCallCount = 0

    private var expectedCreateCallCount: Int?
    private var expectedFetchCallCount: Int?
    private var expectedUpdateCallCount: Int?
    private var expectedDeleteCallCount: Int?

    init() {}

    func setCreateResult(_ result: Result<Folder, Error>) {
        createResult = result
    }

    func setFetchResult(_ result: Result<[Folder], Error>) {
        fetchResult = result
    }

    func setUpdateResult(_ result: Result<Folder, Error>) {
        updateResult = result
    }

    func setDeleteResult(_ result: Result<Folder, Error>) {
        deleteResult = result
    }

    func expectCreate(callCount: Int) {
        expectedCreateCallCount = callCount
    }

    func expectFetch(callCount: Int) {
        expectedFetchCallCount = callCount
    }

    func expectUpdate(callCount: Int) {
        expectedUpdateCallCount = callCount
    }

    func expectDelete(callCount: Int) {
        expectedDeleteCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedCreateCallCount {
            XCTAssertEqual(actualCreateCallCount, expected, "create 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedFetchCallCount {
            XCTAssertEqual(actualFetchCallCount, expected, "fetch 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedUpdateCallCount {
            XCTAssertEqual(actualUpdateCallCount, expected, "update 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedDeleteCallCount {
            XCTAssertEqual(actualDeleteCallCount, expected, "delete 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
    }

    func create(_ item: Folder) async throws -> Folder {
        actualCreateCallCount += 1
        switch createResult {
        case .success(let folder):
            return folder
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockFolderLocalDataSource.createResult 가 설정되지 않았습니다.")
            throw CoreDataStorageError.createFailed
        }
    }

    func fetch() async throws -> [Folder] {
        actualFetchCallCount += 1
        switch fetchResult {
        case .success(let folders):
            return folders
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockFolderLocalDataSource.fetchResult 가 설정되지 않았습니다.")
            throw CoreDataStorageError.fetchFailed
        }
    }

    func update(_ folder: Folder) async throws -> Folder {
        actualUpdateCallCount += 1
        switch updateResult {
        case .success(let updatedFolder):
            return updatedFolder
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockFolderLocalDataSource.updateResult 가 설정되지 않았습니다.")
            throw CoreDataStorageError.updateFailed
        }
    }

    func delete(_ folder: Folder) async throws -> Folder {
        actualDeleteCallCount += 1
        switch deleteResult {
        case .success(let deletedFolder):
            return deletedFolder
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockFolderLocalDataSource.deleteResult 가 설정되지 않았습니다.")
            throw CoreDataStorageError.deleteFailed
        }
    }
}
