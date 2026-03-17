@testable import Core
import Foundation
import XCTest

final class AppLoggerTests: XCTestCase {
    func test_log_호출시_크래시_없음() {
        AppLogger.log(.info, message: "테스트", file: "Test.swift", function: "test()", line: 1)
    }

    func test_편의메서드_호출시_크래시_없음() {
        AppLogger.debug("debug")
        AppLogger.info("info")
        AppLogger.warning("warning")
        AppLogger.error("error")
    }

    func test_빈_메시지_처리() {
        AppLogger.log(.info, message: "", file: "Test.swift", function: "test()", line: 1)
    }

    func test_긴_메시지_처리() {
        let longMessage = String(repeating: "가", count: 10000)
        AppLogger.info(longMessage)
    }

    func test_매우_긴_메시지_처리() {
        let veryLongMessage = String(repeating: "a", count: 100_000)
        AppLogger.info(veryLongMessage)
    }

    func test_특수문자_메시지_처리() {
        AppLogger.info("이모지 🔥 유니코드 日本語 \n 줄바꿈")
    }

    func test_os_log_포맷_특수문자_처리() {
        AppLogger.info("%d %{public}@ {")
    }

    func test_동시_호출_스레드세이프티() {
        let expectation = expectation(description: "concurrent logs")
        expectation.expectedFulfillmentCount = 100

        for index in 0 ..< 100 {
            DispatchQueue.global().async {
                AppLogger.info("concurrent \(index)")
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    func test_백그라운드_스레드_호출() {
        let expectation = expectation(description: "background")
        DispatchQueue.global().async {
            AppLogger.info("background thread")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }

    func test_빈_file_경로_처리() {
        AppLogger.log(.info, message: "test", file: "", function: "test()", line: 1)
    }

    func test_빈_function_처리() {
        AppLogger.log(.info, message: "test", file: "Test.swift", function: "", line: 1)
    }

    func test_line_0_처리() {
        AppLogger.log(.info, message: "test", file: "Test.swift", function: "test()", line: 0)
    }
}
