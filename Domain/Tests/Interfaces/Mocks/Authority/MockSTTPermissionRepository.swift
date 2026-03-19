@testable import Domain
import XCTest

actor MockSTTPermissionRepository: STTPermissionRepository {
    private var checkResult: Result<PermissionStatus, STTPermissionRepositoryError>?
    private var requestResult: Result<PermissionStatus, STTPermissionRepositoryError>?

    private var actualCheckSTTPermissionCallCount = 0
    private var expectedCheckSTTPermissionCallCount: Int?

    private var actualRequestSTTPermissionCallCount = 0
    private var expectedRequestSTTPermissionCallCount: Int?

    func setCheckResult(_ result: Result<PermissionStatus, STTPermissionRepositoryError>) {
        checkResult = result
    }

    func setRequestResult(_ result: Result<PermissionStatus, STTPermissionRepositoryError>) {
        requestResult = result
    }

    func expectCheckSTTPermission(callCount: Int) {
        expectedCheckSTTPermissionCallCount = callCount
    }

    func expectRequestSTTPermission(callCount: Int) {
        expectedRequestSTTPermissionCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedCheckSTTPermissionCallCount {
            XCTAssertEqual(
                actualCheckSTTPermissionCallCount,
                expected,
                "STT 권한 확인 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expected = expectedRequestSTTPermissionCallCount {
            XCTAssertEqual(
                actualRequestSTTPermissionCallCount,
                expected,
                "STT 권한 요청 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
    }

    func checkSTTPermission() async throws(STTPermissionRepositoryError) -> PermissionStatus {
        actualCheckSTTPermissionCallCount += 1

        switch checkResult {
        case .success(let state):
            return state
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockSTTPermissionRepository.checkResult 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockSTTPermissionRepository.checkResult", code: -1))
        }
    }

    func requestSTTPermission() async throws(STTPermissionRepositoryError) -> PermissionStatus {
        actualRequestSTTPermissionCallCount += 1

        switch requestResult {
        case .success(let state):
            return state
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockSTTPermissionRepository.requestResult 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockSTTPermissionRepository.requestResult", code: -1))
        }
    }
}
