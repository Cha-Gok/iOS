@testable import Domain
import XCTest

actor MockFolderRepository: FolderRepository {
    // Results
    private var createResult: Result<Folder, FolderRepositoryError>?
    private var fetchAllResult: Result<[Folder], FolderRepositoryError>?
    private var updateResult: Result<Folder, FolderRepositoryError>?

    // 호출 검증 Count
    private var createCallCount = 0
    private var fetchAllCallCount = 0
    private var updateCallCount = 0

    // 인자 검증
    private var actualName: String?
    private var actualFolder: Folder?

    // Expected Values
    private var expectedCreateCallCount: Int?
    private var expectedFetchAllCallCount: Int?
    private var expectedUpdateCallCount: Int?

    private var expectedName: String?
    private var expectedFolderID: UUID?

    // MARK: - Setup

    func setCreateResult(_ result: Result<Folder, FolderRepositoryError>) {
        createResult = result
    }

    func setFetchAllResult(_ result: Result<[Folder], FolderRepositoryError>) {
        fetchAllResult = result
    }

    func setUpdateResult(_ result: Result<Folder, FolderRepositoryError>) {
        updateResult = result
    }

    // MARK: - Expectations

    func expectCreate(name: String? = nil, callCount: Int) {
        expectedName = name
        expectedCreateCallCount = callCount
    }

    func expectFetchAll(callCount: Int) {
        expectedFetchAllCallCount = callCount
    }

    func expectUpdate(folderID: UUID? = nil, callCount: Int) {
        expectedFolderID = folderID
        expectedUpdateCallCount = callCount
    }

    // MARK: - Verification

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedCreateCallCount {
            XCTAssertEqual(createCallCount, expected, "create call count mismatch", file: file, line: line)
        }

        if let expectedName {
            XCTAssertEqual(actualName, expectedName, "create name argument mismatch", file: file, line: line)
        }

        if let expected = expectedFetchAllCallCount {
            XCTAssertEqual(fetchAllCallCount, expected, "fetchAll call count mismatch", file: file, line: line)
        }

        if let expected = expectedUpdateCallCount {
            XCTAssertEqual(updateCallCount, expected, "update call count mismatch", file: file, line: line)
        }
        if let expectedID = expectedFolderID {
            XCTAssertEqual(actualFolder?.id, expectedID, "update folder ID mismatch", file: file, line: line)
        }
    }

    // MARK: - FolderRepository

    func create(name: String) async throws(FolderRepositoryError) -> Folder {
        createCallCount += 1
        actualName = name

        switch createResult {
        case .success(let folder):
            return folder
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockVoiceNoteCreateRepository.createResult가 설정되지 않았습니다.")
            let error = NSError(domain: "MockFolderRepository.createResult", code: 0)
            throw .unknown(error)
        }
    }

    func fetchAll() async throws(FolderRepositoryError) -> [Folder] {
        fetchAllCallCount += 1

        switch fetchAllResult {
        case .success(let folders):
            return folders
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockVoiceNoteCreateRepository.fetchAll이 설정되지 않았습니다.")
            let error = NSError(domain: "MockFolderRepository.fetchAllResult", code: 0)
            throw .unknown(error)
        }
    }

    func update(_ folder: Folder) async throws(FolderRepositoryError) -> Folder {
        updateCallCount += 1
        actualFolder = folder

        switch updateResult {
        case .success(let updatedFolder):
            return updatedFolder
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockVoiceNoteCreateRepository.updateResult가 설정되지 않았습니다.")
            let error = NSError(domain: "MockFolderRepository.updateResult", code: 0)
            throw .unknown(error)
        }
    }
}
