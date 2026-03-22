@testable import Data
import XCTest

final class MockCheckFirstUserService: CheckFirstUserService, @unchecked Sendable {
    private var firstUserResult: Bool?
    private var actualGetFirstUserCallCount = 0
    private var actualSetUserCallCount = 0
    private var expectedGetFirstUserCallCount: Int?
    private var expectedSetUserCallCount: Int?

    func setFirstUserResult(_ value: Bool) {
        firstUserResult = value
    }

    func expectGetFirstUser(callCount: Int) {
        expectedGetFirstUserCallCount = callCount
    }

    func expectSetUser(callCount: Int) {
        expectedSetUserCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedGetFirstUserCallCount {
            XCTAssertEqual(
                actualGetFirstUserCallCount,
                expected,
                "getFirstUser 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expected = expectedSetUserCallCount {
            XCTAssertEqual(
                actualSetUserCallCount,
                expected,
                "setUser 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
    }

    func getFirstUser() -> Bool {
        guard let firstUserResult else {
            XCTFail("firstUserResult이 설정되지 않았습니다. setFirstUserResult()를 먼저 호출하세요.")
            return false
        }
        actualGetFirstUserCallCount += 1
        return firstUserResult
    }

    func setUser() {
        actualSetUserCallCount += 1
    }
}
