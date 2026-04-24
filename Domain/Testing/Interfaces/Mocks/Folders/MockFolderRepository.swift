@testable import Domain
import XCTest

@MainActor
public final class MockFolderRepository: FolderRepository, @unchecked Sendable {
    // Results
    private var createResult: Result<Folder, FolderRepositoryError>?
    private var fetchAllResult: Result<[Folder], FolderRepositoryError>?
    private var fetchByIDResult: Result<Folder, FolderRepositoryError>?
    private var fetchByKindResults: [FolderKind: Result<Folder, FolderRepositoryError>] = [:]
    private var updateResult: Result<Folder, FolderRepositoryError>?
    private var observeByKindResults: [FolderKind: Result<AsyncStream<[Folder]>, FolderRepositoryError>] = [:]

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
    private var expectedCreateKind: FolderKind?
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

    public func setFetchByKindResult(_ kind: FolderKind, result: Result<Folder, FolderRepositoryError>) {
        fetchByKindResults[kind] = result
    }

    public func setUpdateResult(_ result: Result<Folder, FolderRepositoryError>) {
        updateResult = result
    }

    public func setObserveByKindResult(
        _ kind: FolderKind,
        result: Result<AsyncStream<[Folder]>, FolderRepositoryError>
    ) {
        observeByKindResults[kind] = result
    }

    // MARK: - Expectations

    public func expectCreate(name: String? = nil, kind: FolderKind? = nil, callCount: Int) {
        expectedCreateName = name
        expectedCreateKind = kind
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

        if let expectedCreateKind {
            XCTAssertEqual(
                actualCreatedFolder?.kind,
                expectedCreateKind,
                "생성 폴더 kind 인자가 일치하지 않습니다.",
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

    public func fetch(by kind: FolderKind) throws(FolderRepositoryError) -> Folder {
        switch fetchByKindResults[kind] {
        case .success(let folder):
            return folder
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockFolderRepository.fetchByKindResults[\(kind)]가 설정되지 않았습니다.")
            let error = NSError(domain: "MockFolderRepository.fetchByKindResults", code: 0)
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

    public func observe(by kind: FolderKind) throws(FolderRepositoryError) -> AsyncStream<[Folder]> {
        switch observeByKindResults[kind] {
        case .success(let stream):
            return stream
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockFolderRepository.observeByKindResults[\(kind)]가 설정되지 않았습니다.")
            let error = NSError(domain: "MockFolderRepository.observeByKindResults", code: 0)
            throw .unknown(error)
        }
    }

    // MARK: - Trash operations (no-op defaults; override via test helpers if needed)

    public func observeDeleted() throws(FolderRepositoryError) -> AsyncStream<[Folder]> {
        AsyncStream { $0.finish() }
    }

    public func moveToTrash(id _: UUID, trashFolderID _: UUID) throws(FolderRepositoryError) {}

    public func restore(id _: UUID) throws(FolderRepositoryError) {}

    public func hardDelete(id _: UUID) throws(FolderRepositoryError) {}
}
