@testable import Data
import XCTest

final class MockFirstLaunchService: FirstLaunchService, @unchecked Sendable {
    private var isFirstLaunchResult: Bool?
    private var actualIsFirstLaunchCallCount = 0
    private var actualMarkAsLaunchedCallCount = 0
    private var expectedIsFirstLaunchCallCount: Int?
    private var expectedMarkAsLaunchedCallCount: Int?

    func setIsFirstLaunchResult(_ value: Bool) {
        isFirstLaunchResult = value
    }

    func expectIsFirstLaunch(callCount: Int) {
        expectedIsFirstLaunchCallCount = callCount
    }

    func expectMarkAsLaunched(callCount: Int) {
        expectedMarkAsLaunchedCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedIsFirstLaunchCallCount {
            XCTAssertEqual(
                actualIsFirstLaunchCallCount,
                expected,
                "isFirstLaunch 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expected = expectedMarkAsLaunchedCallCount {
            XCTAssertEqual(
                actualMarkAsLaunchedCallCount,
                expected,
                "markAsLaunched 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
    }

    func isFirstLaunch() -> Bool {
        guard let isFirstLaunchResult else {
            XCTFail("isFirstLaunchResult이 설정되지 않았습니다. setIsFirstLaunchResult()를 먼저 호출하세요.")
            return false
        }
        actualIsFirstLaunchCallCount += 1
        return isFirstLaunchResult
    }

    func markAsLaunched() {
        actualMarkAsLaunchedCallCount += 1
    }
}
