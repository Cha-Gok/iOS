@testable import Domain
import Foundation
import XCTest

final class MockCheckFirstLaunchRepository: CheckFirstLaunchRepository, @unchecked Sendable {
    private var returnValue: Bool = false
    private(set) var checkAndMarkFirstLaunchCallCount = 0
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
                "checkAndMarkFirstLaunch call count mismatch",
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
