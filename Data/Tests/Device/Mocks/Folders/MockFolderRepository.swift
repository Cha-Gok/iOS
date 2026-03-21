@testable import Data
import Domain
import XCTest

actor MockFolderRepository: FolderRepository {
    private var createResult: Result<Folder, FolderRepositoryError>?
    private var fetchAllResult: Result<[Folder], FolderRepositoryError>?
    private var updateResult: Result<Folder, FolderRepositoryError>?

    private var actualCreateCallCount = 0
    private var actualFetchAllCallCount = 0
    private var actualUpdateCallCount = 0

    private var expectedCreateCallCount: Int?
    private var expectedFetchAllCallCount: Int?
    private var expectedUpdateCallCount: Int?

    init() {}

    func setCreateResult(_ result: Result<Folder, FolderRepositoryError>) {
        createResult = result
    }

    func setFetchAllResult(_ result: Result<[Folder], FolderRepositoryError>) {
        fetchAllResult = result
    }

    func setUpdateResult(_ result: Result<Folder, FolderRepositoryError>) {
        updateResult = result
    }

    func expectCreate(callCount: Int) {
        expectedCreateCallCount = callCount
    }

    func expectFetchAll(callCount: Int) {
        expectedFetchAllCallCount = callCount
    }

    func expectUpdate(callCount: Int) {
        expectedUpdateCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedCreateCallCount {
            XCTAssertEqual(actualCreateCallCount, expected, "create 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedFetchAllCallCount {
            XCTAssertEqual(actualFetchAllCallCount, expected, "fetchAll 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedUpdateCallCount {
            XCTAssertEqual(actualUpdateCallCount, expected, "update 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
    }

    func create(name: String) async throws(FolderRepositoryError) -> Folder {
        actualCreateCallCount += 1

        switch createResult {
        case .success(let folder):
            return folder
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockFolderRepository.createResult 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockFolderRepository.createResult", code: -1))
        }
    }

    func fetchAll() async throws(FolderRepositoryError) -> [Folder] {
        actualFetchAllCallCount += 1

        switch fetchAllResult {
        case .success(let folders):
            return folders
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockFolderRepository.fetchAllResult 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockFolderRepository.fetchAllResult", code: -1))
        }
    }

    func update(_ folder: Folder) async throws(FolderRepositoryError) -> Folder {
        actualUpdateCallCount += 1

        switch updateResult {
        case .success(let updatedFolder):
            return updatedFolder
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockFolderRepository.updateResult 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockFolderRepository.updateResult", code: -1))
        }
    }
}
