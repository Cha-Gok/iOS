import XCTest
@testable import Domain

actor MockWorkSpaceRepository: WorkSpaceRepository {

    // Results
    private var rootURLResult: Result<URL, WorkSpaceRootURLRepositoryError>?
    private var basicFolderResult: Result<Folder, WorkSpaceBasicFolderRepositoryError>?

    // 호출 검증 Count
    private(set) var fetchRootURLCallCount = 0
    private(set) var fetchOrCreateBasicFolderCallCount = 0

    // Expected Call Counts
    private var expectedFetchRootURLCallCount: Int?
    private var expectedFetchOrCreateBasicFolderCallCount: Int?

    // 작업 도중 취소 테스트를 위한 제어 변수
    private var shouldWaitUntilCancelled = false

    // MARK: - Setup

    func setRootURLResult(_ result: Result<URL, WorkSpaceRootURLRepositoryError>) {
        self.rootURLResult = result
    }

    func setBasicFolderResult(_ result: Result<Folder, WorkSpaceBasicFolderRepositoryError>) {
        self.basicFolderResult = result
    }

    func setWaitUntilCancelled(_ shouldWait: Bool) {
        self.shouldWaitUntilCancelled = shouldWait
    }

    // MARK: - Expectations

    func expectFetchRootURL(callCount: Int) {
        expectedFetchRootURLCallCount = callCount
    }

    func expectFetchOrCreateBasicFolder(callCount: Int) {
        expectedFetchOrCreateBasicFolderCallCount = callCount
    }

    // MARK: - Verification

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedFetchRootURLCallCount {
            XCTAssertEqual(fetchRootURLCallCount, expected, "fetchRootURL call count mismatch", file: file, line: line)
        }
        if let expected = expectedFetchOrCreateBasicFolderCallCount {
            XCTAssertEqual(fetchOrCreateBasicFolderCallCount, expected, "fetchOrCreateBasicFolder call count mismatch", file: file, line: line)
        }
    }

    // MARK: - WorkSpaceRepository

    func fetchRootURL() async throws(WorkSpaceRootURLRepositoryError) -> URL {
        fetchRootURLCallCount += 1

        guard let result = rootURLResult else {
            fatalError("MockWorkSpaceRepository.rootURLResult not set")
        }

        switch result {
            case .success(let url):
                return url
            case .failure(let error):
                throw error
        }
    }

    func fetchOrCreateBasicFolder() async throws(WorkSpaceBasicFolderRepositoryError) -> Folder {
        fetchOrCreateBasicFolderCallCount += 1

        guard let result = basicFolderResult else {
            fatalError("MockWorkSpaceRepository.basicFolderResult not set")
        }

        switch result {
            case .success(let folder):
                return folder
            case .failure(let error):
                throw error
        }
    }
}
