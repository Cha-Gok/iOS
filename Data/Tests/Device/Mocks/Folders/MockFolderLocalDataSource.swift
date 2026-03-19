@testable import Data
import Domain
import XCTest

actor MockFolderLocalDataSource: FolderLocalDataSource {
    private var createResult: Result<Folder, Error>?
    private var fetchResult: Result<[Folder], Error>?
    private var updateResult: Result<Folder, Error>?

    private var actualCreateCallCount = 0
    private var actualFetchCallCount = 0
    private var actualUpdateCallCount = 0

    private var expectedCreateCallCount: Int?
    private var expectedFetchCallCount: Int?
    private var expectedUpdateCallCount: Int?

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

    func expectCreate(callCount: Int) {
        expectedCreateCallCount = callCount
    }

    func expectFetch(callCount: Int) {
        expectedFetchCallCount = callCount
    }

    func expectUpdate(callCount: Int) {
        expectedUpdateCallCount = callCount
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
    }

    func create(name: String) async throws -> Folder {
        actualCreateCallCount += 1
        switch createResult {
        case .success(let folder):
            return folder
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockFolderLocalDataSource.createResult 가 설정되지 않았습니다.")
            throw NSError(domain: "MockFolderLocalDataSource.createResult", code: -1)
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
            throw NSError(domain: "MockFolderLocalDataSource.fetchResult", code: -1)
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
            throw NSError(domain: "MockFolderLocalDataSource.updateResult", code: -1)
        }
    }
}
