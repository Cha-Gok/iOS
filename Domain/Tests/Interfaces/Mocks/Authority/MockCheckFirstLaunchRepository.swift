@testable import Domain
import Foundation
import XCTest

final class MockCheckFirstLaunchRepository: CheckFirstLaunchRepository, @unchecked Sendable {
    private var returnValue: Bool = false
    private var checkAndMarkFirstLaunchCallCount = 0
    private var expectedCallCount: Int?

    func setReturnValue(_ value: Bool) {
        returnValue = value
    }

    func expectCheckAndMarkFirstLaunch(callCount: Int) {
        expectedCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedCallCount {
            XCTAssertEqual(
                checkAndMarkFirstLaunchCallCount,
                expected,
                "첫 실행 확인 및 마킹 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
    }

    func checkAndMarkFirstLaunch() -> Bool {
        checkAndMarkFirstLaunchCallCount += 1

        return returnValue
    }
}
