@testable import Core
import Foundation
import XCTest

final class LogLevelTests: XCTestCase {}

// MARK: - 성공 케이스

extension LogLevelTests {
    func test_로그레벨정의_rawValue확인시_기대하는순서로정의되어있다() {
        // Given & When & Then
        XCTAssertEqual(LogLevel.debug.rawValue, 0)
        XCTAssertEqual(LogLevel.info.rawValue, 1)
        XCTAssertEqual(LogLevel.warning.rawValue, 2)
        XCTAssertEqual(LogLevel.error.rawValue, 3)
    }

    func test_로그레벨정의_레벨비교시_심각도순서가올바르다() {
        // Given & When & Then
        XCTAssertLessThan(LogLevel.debug.rawValue, LogLevel.info.rawValue)
        XCTAssertLessThan(LogLevel.info.rawValue, LogLevel.warning.rawValue)
        XCTAssertLessThan(LogLevel.warning.rawValue, LogLevel.error.rawValue)
    }

    func test_로그레벨정의_symbol확인시_모든레벨에심볼이존재한다() {
        // Given & When & Then
        XCTAssertFalse(LogLevel.debug.symbol.isEmpty)
        XCTAssertFalse(LogLevel.info.symbol.isEmpty)
        XCTAssertFalse(LogLevel.warning.symbol.isEmpty)
        XCTAssertFalse(LogLevel.error.symbol.isEmpty)
    }

    func test_CaseIterable준수_모든케이스조회시_4가지레벨이모두포함되어있다() {
        // Given
        let expectedLevels: [LogLevel] = [.debug, .info, .warning, .error]

        // When
        let allLevels = LogLevel.allCases

        // Then
        XCTAssertEqual(allLevels.count, 4)
        XCTAssertEqual(allLevels, expectedLevels)
    }
}
