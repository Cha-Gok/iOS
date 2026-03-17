@testable import Core
import Foundation
import XCTest

final class AppLoggerTests: XCTestCase {}

// MARK: - 성공 케이스

extension AppLoggerTests {
    func test_정상적인메시지_로그호출시_크래시없이동작한다() {
        // Given
        let message = "테스트"
        let file = "Test.swift"
        let function = "test()"
        let line = 1

        // When & Then
        AppLogger.log(.info, message: message, file: file, function: function, line: line)
    }

    func test_다양한로그레벨_편의메서드호출시_크래시없이동작한다() {
        // Given
        let message = "log message"

        // When & Then
        AppLogger.debug(message)
        AppLogger.info(message)
        AppLogger.warning(message)
        AppLogger.error(message)
    }

    func test_빈메시지_로그호출시_정상적으로처리된다() {
        // Given
        let emptyMessage = ""

        // When & Then
        AppLogger.info(emptyMessage)
    }

    func test_매우긴메시지_로그호출시_성능저하나크래시없이처리된다() {
        // Given
        let veryLongMessage = String(repeating: "a", count: 100_000)

        // When & Then
        AppLogger.info(veryLongMessage)
    }

    func test_특수문자및이모지포함메시지_로그호출시_정상적으로출력된다() {
        // Given
        let specialMessage = "이모지 🔥 유니코드 日本語 \n 줄바꿈"

        // When & Then
        AppLogger.info(specialMessage)
    }

    func test_os_log포맷포함메시지_로그호출시_포맷에러없이정상처리된다() {
        // Given
        let formatMessage = "%d %{public}@ {"

        // When & Then
        AppLogger.info(formatMessage)
    }

    func test_여러스레드에서동시호출_로그호출시_스레드세이프하게동작한다() {
        // Given
        let expectation = expectation(description: "concurrent logs")
        let totalCount = 100
        expectation.expectedFulfillmentCount = totalCount

        // When
        for index in 0 ..< totalCount {
            DispatchQueue.global().async {
                AppLogger.info("concurrent \(index)")
                expectation.fulfill()
            }
        }

        // Then
        wait(for: [expectation], timeout: 5)
    }

    func test_백그라운드스레드_로그호출시_정상적으로동작한다() {
        // Given
        let expectation = expectation(description: "background")

        // When
        DispatchQueue.global().async {
            AppLogger.info("background thread")
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 2)
    }
}

// MARK: - 경계 값 케이스

extension AppLoggerTests {
    func test_빈파일경로_로그호출시_크래시없이동작한다() {
        // Given
        let file = ""

        // When & Then
        AppLogger.log(.info, message: "test", file: file, function: "test()", line: 1)
    }

    func test_빈함수명_로그호출시_크래시없이동작한다() {
        // Given
        let function = ""

        // When & Then
        AppLogger.log(.info, message: "test", file: "Test.swift", function: function, line: 1)
    }

    func test_라인번호0_로그호출시_크래시없이동작한다() {
        // Given
        let line = 0

        // When & Then
        AppLogger.log(.info, message: "test", file: "Test.swift", function: "test()", line: line)
    }
}
