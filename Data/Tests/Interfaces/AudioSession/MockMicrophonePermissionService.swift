@testable import Data
import Domain
import XCTest

actor MockMicrophonePermissionService: MicrophonePermissionService {
    private var checkResult: PermissionStatus?
    private var requestResult: PermissionStatus?

    private var actualCheckCallCount = 0
    private var actualRequestCallCount = 0
    private var expectedCheckCallCount: Int?
    private var expectedRequestCallCount: Int?

    func setCheckResult(_ status: PermissionStatus) {
        checkResult = status
    }

    func setRequestResult(_ status: PermissionStatus) {
        requestResult = status
    }

    func expectCheck(callCount: Int) {
        expectedCheckCallCount = callCount
    }

    func expectRequest(callCount: Int) {
        expectedRequestCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedCheckCallCount {
            XCTAssertEqual(
                actualCheckCallCount,
                expected,
                "checkPermission 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expected = expectedRequestCallCount {
            XCTAssertEqual(
                actualRequestCallCount,
                expected,
                "requestPermission 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
    }

    func checkPermission() async -> PermissionStatus {
        guard let checkResult else {
            XCTFail("checkResult이 설정되지 않았습니다. setCheckResult()를 먼저 호출하세요.")
            return .notDetermined
        }
        actualCheckCallCount += 1
        return checkResult
    }

    func requestPermission() async -> PermissionStatus {
        guard let requestResult else {
            XCTFail("requestResult이 설정되지 않았습니다. setRequestResult()를 먼저 호출하세요.")
            return .notDetermined
        }
        actualRequestCallCount += 1
        return requestResult
    }
}
