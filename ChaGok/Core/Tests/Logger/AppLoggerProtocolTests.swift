import Foundation
import XCTest
@testable import Core

final class AppLoggerProtocolTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockLogger.reset()
    }

    func test_debug_호출시_log에_debug_전달() {
        MockLogger.debug("테스트 메시지")

        XCTAssertEqual(MockLogger.recordedLogs.count, 1)
        XCTAssertEqual(MockLogger.recordedLogs[0].level, .debug)
        XCTAssertEqual(MockLogger.recordedLogs[0].message, "테스트 메시지")
    }

    func test_info_호출시_log에_info_전달() {
        MockLogger.info("정보 메시지")

        XCTAssertEqual(MockLogger.recordedLogs.count, 1)
        XCTAssertEqual(MockLogger.recordedLogs[0].level, .info)
        XCTAssertEqual(MockLogger.recordedLogs[0].message, "정보 메시지")
    }

    func test_warning_호출시_log에_warning_전달() {
        MockLogger.warning("경고 메시지")

        XCTAssertEqual(MockLogger.recordedLogs.count, 1)
        XCTAssertEqual(MockLogger.recordedLogs[0].level, .warning)
        XCTAssertEqual(MockLogger.recordedLogs[0].message, "경고 메시지")
    }

    func test_errorString_호출시_log에_error_전달() {
        MockLogger.error("에러 메시지")

        XCTAssertEqual(MockLogger.recordedLogs.count, 1)
        XCTAssertEqual(MockLogger.recordedLogs[0].level, .error)
        XCTAssertEqual(MockLogger.recordedLogs[0].message, "에러 메시지")
    }

    func test_errorError_호출시_String_describing_전달() {
        struct TestError: Error {}
        MockLogger.error(TestError())

        XCTAssertEqual(MockLogger.recordedLogs.count, 1)
        XCTAssertEqual(MockLogger.recordedLogs[0].level, .error)
        XCTAssertEqual(MockLogger.recordedLogs[0].message, "TestError()")
    }

    func test_여러_로그_연속_호출시_순서대로_기록() {
        MockLogger.debug("1")
        MockLogger.info("2")
        MockLogger.warning("3")
        MockLogger.error("4")

        XCTAssertEqual(MockLogger.recordedLogs.count, 4)
        XCTAssertEqual(MockLogger.recordedLogs[0].level, .debug)
        XCTAssertEqual(MockLogger.recordedLogs[0].message, "1")
        XCTAssertEqual(MockLogger.recordedLogs[1].level, .info)
        XCTAssertEqual(MockLogger.recordedLogs[1].message, "2")
        XCTAssertEqual(MockLogger.recordedLogs[2].level, .warning)
        XCTAssertEqual(MockLogger.recordedLogs[2].message, "3")
        XCTAssertEqual(MockLogger.recordedLogs[3].level, .error)
        XCTAssertEqual(MockLogger.recordedLogs[3].message, "4")
    }

    func test_빈_메시지_처리() {
        MockLogger.info("")

        XCTAssertEqual(MockLogger.recordedLogs.count, 1)
        XCTAssertEqual(MockLogger.recordedLogs[0].message, "")
    }

    func test_특수문자_메시지_처리() {
        let message = "이모지 🔥 유니코드 日本語 \n 줄바꿈"
        MockLogger.info(message)

        XCTAssertEqual(MockLogger.recordedLogs.count, 1)
        XCTAssertEqual(MockLogger.recordedLogs[0].message, message)
    }

    func test_localizedDescription_nil인_Error_처리() {
        struct PlainError: Error {}
        MockLogger.error(PlainError())

        XCTAssertEqual(MockLogger.recordedLogs.count, 1)
        XCTAssertEqual(MockLogger.recordedLogs[0].level, .error)
        XCTAssertFalse(MockLogger.recordedLogs[0].message.isEmpty)
    }

    func test_LocalizedError_미준수_Error_처리() {
        struct CustomError: Error {
            let code: Int
        }
        MockLogger.error(CustomError(code: 42))

        XCTAssertEqual(MockLogger.recordedLogs.count, 1)
        XCTAssertEqual(MockLogger.recordedLogs[0].level, .error)
    }

    func test_null_nil_문자열_처리() {
        MockLogger.info("null")
        MockLogger.info("nil")

        XCTAssertEqual(MockLogger.recordedLogs.count, 2)
        XCTAssertEqual(MockLogger.recordedLogs[0].message, "null")
        XCTAssertEqual(MockLogger.recordedLogs[1].message, "nil")
    }

    func test_개행_탭_메시지_처리() {
        let message = "line1\nline2\t"
        MockLogger.info(message)

        XCTAssertEqual(MockLogger.recordedLogs.count, 1)
        XCTAssertEqual(MockLogger.recordedLogs[0].message, message)
    }
}
