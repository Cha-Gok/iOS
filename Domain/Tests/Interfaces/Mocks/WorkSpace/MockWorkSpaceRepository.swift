@testable import Domain
import XCTest

actor MockWorkSpaceRepository: WorkSpaceRepository {
    // Results
    private var rootURLResult: Result<URL, WorkSpaceRootURLRepositoryError>?
    private var basicFolderResult: Result<Folder, WorkSpaceBasicFolderRepositoryError>?

    // 호출 검증 Count
    private var fetchRootURLCallCount = 0
    private var fetchOrCreateBasicFolderCallCount = 0

    // Expected Call Counts
    private var expectedFetchRootURLCallCount: Int?
    private var expectedFetchOrCreateBasicFolderCallCount: Int?

    /// 작업 도중 취소 테스트를 위한 제어 변수
    private var shouldWaitUntilCancelled = false

    // MARK: - Setup

    func setRootURLResult(_ result: Result<URL, WorkSpaceRootURLRepositoryError>) {
        rootURLResult = result
    }

    func setBasicFolderResult(_ result: Result<Folder, WorkSpaceBasicFolderRepositoryError>) {
        basicFolderResult = result
    }

    func setWaitUntilCancelled(_ shouldWait: Bool) {
        shouldWaitUntilCancelled = shouldWait
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
            XCTAssertEqual(fetchRootURLCallCount, expected, "루트 URL 조회 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedFetchOrCreateBasicFolderCallCount {
            XCTAssertEqual(
                fetchOrCreateBasicFolderCallCount,
                expected,
                "기본 폴더 조회 또는 생성 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
    }

    // MARK: - WorkSpaceRepository

    func fetchRootURL() async throws(WorkSpaceRootURLRepositoryError) -> URL {
        fetchRootURLCallCount += 1

        guard let result = rootURLResult else {
            XCTFail("MockWorkSpaceRepository.rootURLResult 가 설정되지 않았습니다.")
            fatalError("MockWorkSpaceRepository.rootURLResult 가 설정되지 않았습니다.")
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
            XCTFail("MockWorkSpaceRepository.basicFolderResult 가 설정되지 않았습니다.")
            fatalError("MockWorkSpaceRepository.basicFolderResult 가 설정되지 않았습니다.")
        }

        switch result {
        case .success(let folder):
            return folder
        case .failure(let error):
            throw error
        }
    }
}
