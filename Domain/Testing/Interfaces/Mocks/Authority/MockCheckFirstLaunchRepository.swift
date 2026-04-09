@testable import Domain
import Foundation
import XCTest

public final class MockCheckFirstLaunchRepository: CheckFirstLaunchRepository, @unchecked Sendable {
    public init() {}

    private var returnValue: Bool = false
    private var checkIsFirstLaunchCallCount = 0
    private var checkAndMarkFirstLaunchCallCount = 0
    private var expectedCallCount: Int?
    private var expectedCheckIsFirstLaunchCallCount: Int?

    public func setReturnValue(_ value: Bool) {
        returnValue = value
    }

    public func expectCheckAndMarkFirstLaunch(callCount: Int) {
        expectedCallCount = callCount
    }

    public func expectCheckIsFirstLaunch(callCount: Int) {
        expectedCheckIsFirstLaunchCallCount = callCount
    }

    public func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedCallCount {
            XCTAssertEqual(
                checkAndMarkFirstLaunchCallCount,
                expected,
                "첫 실행 확인 및 마킹 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expectedCheckIs = expectedCheckIsFirstLaunchCallCount {
            XCTAssertEqual(
                checkIsFirstLaunchCallCount,
                expectedCheckIs,
                "첫 실행 확인(단순 조회) 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
    }

    public func checkIsFirstLaunch() -> Bool {
        checkIsFirstLaunchCallCount += 1
        return returnValue
    }

    public func checkAndMarkFirstLaunch() -> Bool {
        checkAndMarkFirstLaunchCallCount += 1

        return returnValue
    }
}
