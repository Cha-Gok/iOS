@testable import Domain
import XCTest

actor MockMicrophonePermissionRepository: MicrophonePermissionRepository {
    private var checkResult: Result<PermissionStatus, MicrophonePermissionRepositoryError>?
    private var requestResult: Result<PermissionStatus, MicrophonePermissionRepositoryError>?

    private var actualCheckMicrophonePermissionCallCount = 0
    private var expectedCheckMicrophonePermissionCallCount: Int?

    private var actualRequestMicrophonePermissionCallCount = 0
    private var expectedRequestMicrophonePermissionCallCount: Int?

    func setCheckResult(_ result: Result<PermissionStatus, MicrophonePermissionRepositoryError>) {
        checkResult = result
    }

    func setRequestResult(_ result: Result<PermissionStatus, MicrophonePermissionRepositoryError>) {
        requestResult = result
    }

    func expectCheckMicrophonePermission(callCount: Int) {
        expectedCheckMicrophonePermissionCallCount = callCount
    }

    func expectRequestMicrophonePermission(callCount: Int) {
        expectedRequestMicrophonePermissionCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedCheckMicrophonePermissionCallCount {
            XCTAssertEqual(
                actualCheckMicrophonePermissionCallCount,
                expected,
                "마이크 권한 확인 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expected = expectedRequestMicrophonePermissionCallCount {
            XCTAssertEqual(
                actualRequestMicrophonePermissionCallCount,
                expected,
                "마이크 권한 요청 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
    }

    func checkMicrophonePermission() async throws(MicrophonePermissionRepositoryError) -> PermissionStatus {
        actualCheckMicrophonePermissionCallCount += 1

        switch checkResult {
        case .success(let state):
            return state
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockMicrophonePermissionRepository.checkResult 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockMicrophonePermissionRepository.checkResult", code: -1))
        }
    }

    func requestMicrophonePermission() async throws(MicrophonePermissionRepositoryError) -> PermissionStatus {
        actualRequestMicrophonePermissionCallCount += 1

        switch requestResult {
        case .success(let state):
            return state
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockMicrophonePermissionRepository.requestResult 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockMicrophonePermissionRepository.requestResult", code: -1))
        }
    }
}
