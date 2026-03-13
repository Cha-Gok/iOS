import XCTest
@testable import Domain

actor MockFolderRepository: FolderRepository {

    // Results
    private var createResult: Result<Folder, FolderRepositoryError>?
    private var fetchAllResult: Result<[Folder], FolderRepositoryError>?
    private var updateResult: Result<Folder, FolderRepositoryError>?

    // 호출 검증 Count
    private(set) var createCallCount = 0
    private(set) var fetchAllCallCount = 0
    private(set) var updateCallCount = 0

    // Expected Call Counts
    private var expectedCreateCallCount: Int?
    private var expectedFetchAllCallCount: Int?
    private var expectedUpdateCallCount: Int?

    // MARK: - Setup

    func setCreateResult(_ result: Result<Folder, FolderRepositoryError>) {
        self.createResult = result
    }

    func setFetchAllResult(_ result: Result<[Folder], FolderRepositoryError>) {
        self.fetchAllResult = result
    }

    func setUpdateResult(_ result: Result<Folder, FolderRepositoryError>) {
        self.updateResult = result
    }

    // MARK: - Expectations

    func expectCreate(callCount: Int) {
        expectedCreateCallCount = callCount
    }

    func expectFetchAll(callCount: Int) {
        expectedFetchAllCallCount = callCount
    }

    func expectUpdate(callCount: Int) {
        expectedUpdateCallCount = callCount
    }

    // MARK: - Verification

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedCreateCallCount {
            XCTAssertEqual(createCallCount, expected, "create call count mismatch", file: file, line: line)
        }
        if let expected = expectedFetchAllCallCount {
            XCTAssertEqual(fetchAllCallCount, expected, "fetchAll call count mismatch", file: file, line: line)
        }
        if let expected = expectedUpdateCallCount {
            XCTAssertEqual(updateCallCount, expected, "update call count mismatch", file: file, line: line)
        }
    }

    // MARK: - FolderRepository

    func create(name: String) async throws(FolderRepositoryError) -> Folder {
        createCallCount += 1

        guard let result = createResult else {
            fatalError("MockFolderRepository.createResult not set")
        }

        switch result {
            case .success(let folder):
                return folder
            case .failure(let error):
                throw error
        }
    }

    func fetchAll() async throws(FolderRepositoryError) -> [Folder] {
        fetchAllCallCount += 1

        guard let result = fetchAllResult else {
            fatalError("MockFolderRepository.fetchAllResult not set")
        }

        switch result {
            case .success(let folders):
                return folders
            case .failure(let error):
                throw error
        }
    }

    func update(_ folder: Folder) async throws(FolderRepositoryError) -> Folder {
        updateCallCount += 1

        guard let result = updateResult else {
            fatalError("MockFolderRepository.updateResult not set")
        }

        switch result {
            case .success(let updatedFolder):
                return updatedFolder
            case .failure(let error):
                throw error
        }
    }
}
