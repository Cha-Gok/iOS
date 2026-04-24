@testable import Domain
import XCTest

@MainActor
public final class MockFolderRepository: FolderRepository, @unchecked Sendable {
    // Results
    private var createResult: Result<Folder, FolderRepositoryError>?
    private var fetchAllResult: Result<[Folder], FolderRepositoryError>?
    private var fetchByIDResult: Result<Folder, FolderRepositoryError>?
    private var updateResult: Result<Folder, FolderRepositoryError>?
    private var observeAllResult: Result<AsyncStream<[Folder]>, FolderRepositoryError>?

    // 호출 검증 Count
    private var createCallCount = 0
    private var fetchAllCallCount = 0
    private var fetchByIDCallCount = 0
    private var updateCallCount = 0

    // 인자 검증
    private var actualCreatedFolder: Folder?
    private var actualFolder: Folder?
    private var actualFetchByID: UUID?

    // Expected Values
    private var expectedCreateCallCount: Int?
    private var expectedFetchAllCallCount: Int?
    private var expectedFetchByIDCallCount: Int?
    private var expectedUpdateCallCount: Int?

    private var expectedCreateName: String?
    private var expectedCreateIsDeletable: Bool?
    private var expectedFolderID: UUID?
    private var expectedFetchByID: UUID?

    public init() {}

    // MARK: - Setup

    public func setCreateResult(_ result: Result<Folder, FolderRepositoryError>) {
        createResult = result
    }

    public func setFetchAllResult(_ result: Result<[Folder], FolderRepositoryError>) {
        fetchAllResult = result
    }

    public func setFetchByIDResult(_ result: Result<Folder, FolderRepositoryError>) {
        fetchByIDResult = result
    }

    public func setUpdateResult(_ result: Result<Folder, FolderRepositoryError>) {
        updateResult = result
    }

    public func setObserveAllResult(_ result: Result<AsyncStream<[Folder]>, FolderRepositoryError>) {
        observeAllResult = result
    }

    // MARK: - Expectations

    public func expectCreate(name: String? = nil, isDeletable: Bool? = nil, callCount: Int) {
        expectedCreateName = name
        expectedCreateIsDeletable = isDeletable
        expectedCreateCallCount = callCount
    }

    public func expectFetchAll(callCount: Int) {
        expectedFetchAllCallCount = callCount
    }

    public func expectFetchByID(id: UUID? = nil, callCount: Int) {
        expectedFetchByID = id
        expectedFetchByIDCallCount = callCount
    }

    public func expectUpdate(folderID: UUID? = nil, callCount: Int) {
        expectedFolderID = folderID
        expectedUpdateCallCount = callCount
    }

    // MARK: - Verification

    public func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedCreateCallCount {
            XCTAssertEqual(
                createCallCount, expected, "생성 호출 횟수가 일치하지 않습니다.", file: file, line: line
            )
        }

        if let expectedCreateName {
            XCTAssertEqual(
                actualCreatedFolder?.name,
                expectedCreateName,
                "생성 이름 인자가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }

        if let expectedCreateIsDeletable {
            XCTAssertEqual(
                actualCreatedFolder?.isDeletable,
                expectedCreateIsDeletable,
                "생성 삭제 가능 여부 인자가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }

        if let expected = expectedFetchAllCallCount {
            XCTAssertEqual(
                fetchAllCallCount, expected, "전체 조회 호출 횟수가 일치하지 않습니다.", file: file, line: line
            )
        }

        if let expected = expectedFetchByIDCallCount {
            XCTAssertEqual(
                fetchByIDCallCount, expected, "ID 조회 호출 횟수가 일치하지 않습니다.", file: file, line: line
            )
        }

        if let expectedID = expectedFetchByID {
            XCTAssertEqual(
                actualFetchByID, expectedID, "ID 조회 인자가 일치하지 않습니다.", file: file, line: line
            )
        }

        if let expected = expectedUpdateCallCount {
            XCTAssertEqual(
                updateCallCount, expected, "수정 호출 횟수가 일치하지 않습니다.", file: file, line: line
            )
        }
        if let expectedID = expectedFolderID {
            XCTAssertEqual(
                actualFolder?.id, expectedID, "수정 폴더 ID가 일치하지 않습니다.", file: file, line: line
            )
        }
    }

    // MARK: - FolderRepository

    public func create(_ folder: Folder) throws(FolderRepositoryError) -> Folder {
        createCallCount += 1
        actualCreatedFolder = folder

        switch createResult {
        case .success(let folder):
            return folder
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockFolderRepository.createResult가 설정되지 않았습니다.")
            let error = NSError(domain: "MockFolderRepository.createResult", code: 0)
            throw .unknown(error)
        }
    }

    public func fetch(by id: UUID) throws(FolderRepositoryError) -> Folder {
        fetchByIDCallCount += 1
        actualFetchByID = id

        switch fetchByIDResult {
        case .success(let folder):
            return folder
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockFolderRepository.fetchByIDResult가 설정되지 않았습니다.")
            let error = NSError(domain: "MockFolderRepository.fetchByIDResult", code: 0)
            throw .unknown(error)
        }
    }

    public func fetchAll() throws(FolderRepositoryError) -> [Folder] {
        fetchAllCallCount += 1

        switch fetchAllResult {
        case .success(let folders):
            return folders
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockFolderRepository.fetchAll이 설정되지 않았습니다.")
            let error = NSError(domain: "MockFolderRepository.fetchAllResult", code: 0)
            throw .unknown(error)
        }
    }

    public func update(_ folder: Folder) throws(FolderRepositoryError) -> Folder {
        updateCallCount += 1
        actualFolder = folder

        switch updateResult {
        case .success(let updatedFolder):
            return updatedFolder
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockFolderRepository.updateResult가 설정되지 않았습니다.")
            let error = NSError(domain: "MockFolderRepository.updateResult", code: 0)
            throw .unknown(error)
        }
    }

    public func observeAll() throws(FolderRepositoryError) -> AsyncStream<[Folder]> {
        switch observeAllResult {
        case .success(let stream):
            return stream
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockFolderRepository.observeAllResult가 설정되지 않았습니다.")
            let error = NSError(domain: "MockFolderRepository.observeAllResult", code: 0)
            throw .unknown(error)
        }
    }
}
