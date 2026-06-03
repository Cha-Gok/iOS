@testable import Core
import Foundation
import XCTest

final class AppLoggerProtocolTests: XCTestCase {}

// MARK: - 성공 케이스

extension AppLoggerProtocolTests {
    func test_debug메서드_로그호출시_debug레벨로정확히기록된다() {
        MockLogger.reset()

        // Given
        let message = "테스트 메시지"

        // When
        MockLogger.debug(message)

        // Then
        XCTAssertEqual(MockLogger.recordedLogs.count, 1)
        XCTAssertEqual(MockLogger.recordedLogs[0].level, .debug)
        XCTAssertEqual(MockLogger.recordedLogs[0].message, message)
    }

    func test_info메서드_로그호출시_info레벨로정확히기록된다() {
        MockLogger.reset()

        // Given
        let message = "정보 메시지"

        // When
        MockLogger.info(message)

        // Then
        XCTAssertEqual(MockLogger.recordedLogs.count, 1)
        XCTAssertEqual(MockLogger.recordedLogs[0].level, .info)
        XCTAssertEqual(MockLogger.recordedLogs[0].message, message)
    }

    func test_warning메서드_로그호출시_warning레벨로정확히기록된다() {
        MockLogger.reset()

        // Given
        let message = "경고 메시지"

        // When
        MockLogger.warning(message)

        // Then
        XCTAssertEqual(MockLogger.recordedLogs.count, 1)
        XCTAssertEqual(MockLogger.recordedLogs[0].level, .warning)
        XCTAssertEqual(MockLogger.recordedLogs[0].message, message)
    }

    func test_errorString메서드_로그호출시_error레벨로정확히기록된다() {
        MockLogger.reset()

        // Given
        let message = "에러 메시지"

        // When
        MockLogger.error(message)

        // Then
        XCTAssertEqual(MockLogger.recordedLogs.count, 1)
        XCTAssertEqual(MockLogger.recordedLogs[0].level, .error)
        XCTAssertEqual(MockLogger.recordedLogs[0].message, message)
    }

    func test_errorError객체_로그호출시_Error의문자열설명이정확히기록된다() {
        MockLogger.reset()

        // Given
        struct TestError: Error {}
        let error = TestError()

        // When
        MockLogger.error(error)

        // Then
        XCTAssertEqual(MockLogger.recordedLogs.count, 1)
        XCTAssertEqual(MockLogger.recordedLogs[0].level, .error)
        XCTAssertEqual(MockLogger.recordedLogs[0].message, String(describing: error))
    }

    func test_여러로그_연속호출시_호출한순서대로정확히기록된다() {
        MockLogger.reset()

        // Given
        let messages = ["1", "2", "3", "4"]
        let levels: [LogLevel] = [.debug, .info, .warning, .error]

        // When
        MockLogger.debug(messages[0])
        MockLogger.info(messages[1])
        MockLogger.warning(messages[2])
        MockLogger.error(messages[3])

        // Then
        XCTAssertEqual(MockLogger.recordedLogs.count, 4)
        for (index, level) in levels.enumerated() {
            XCTAssertEqual(MockLogger.recordedLogs[index].level, level)
            XCTAssertEqual(MockLogger.recordedLogs[index].message, messages[index])
        }
    }

    func test_빈메시지_로그호출시_정상적으로기록된다() {
        MockLogger.reset()

        // Given
        let emptyMessage = ""

        // When
        MockLogger.info(emptyMessage)

        // Then
        XCTAssertEqual(MockLogger.recordedLogs.count, 1)
        XCTAssertEqual(MockLogger.recordedLogs[0].message, emptyMessage)
    }

    func test_특수문자포함메시지_로그호출시_정상적으로기록된다() {
        MockLogger.reset()

        // Given
        let specialMessage = "이모지 🔥 유니코드 日本語 \n 줄바꿈"

        // When
        MockLogger.info(specialMessage)

        // Then
        XCTAssertEqual(MockLogger.recordedLogs.count, 1)
        XCTAssertEqual(MockLogger.recordedLogs[0].message, specialMessage)
    }

    func test_LocalizedError미준수객체_로그호출시_기본문자열설명으로기록된다() {
        MockLogger.reset()

        // Given
        struct CustomError: Error {
            let code: Int
        }
        let error = CustomError(code: 42)

        // When
        MockLogger.error(error)

        // Then
        XCTAssertEqual(MockLogger.recordedLogs.count, 1)
        XCTAssertEqual(MockLogger.recordedLogs[0].level, .error)
        XCTAssertFalse(MockLogger.recordedLogs[0].message.isEmpty)
    }
}
