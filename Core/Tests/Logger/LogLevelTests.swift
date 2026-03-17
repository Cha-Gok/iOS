import Foundation
import XCTest
@testable import Core

final class LogLevelTests: XCTestCase {
    func test_rawValue_순서() {
        XCTAssertEqual(LogLevel.debug.rawValue, 0)
        XCTAssertEqual(LogLevel.info.rawValue, 1)
        XCTAssertEqual(LogLevel.warning.rawValue, 2)
        XCTAssertEqual(LogLevel.error.rawValue, 3)
    }

    func test_레벨_비교() {
        XCTAssertLessThan(LogLevel.debug.rawValue, LogLevel.info.rawValue)
        XCTAssertLessThan(LogLevel.info.rawValue, LogLevel.warning.rawValue)
        XCTAssertLessThan(LogLevel.warning.rawValue, LogLevel.error.rawValue)
    }

    func test_symbol_존재() {
        XCTAssertFalse(LogLevel.debug.symbol.isEmpty)
        XCTAssertFalse(LogLevel.info.symbol.isEmpty)
        XCTAssertFalse(LogLevel.warning.symbol.isEmpty)
        XCTAssertFalse(LogLevel.error.symbol.isEmpty)
    }

    func test_CaseIterable() {
        let allLevels = LogLevel.allCases
        XCTAssertEqual(allLevels.count, 4)
        XCTAssertEqual(allLevels, [.debug, .info, .warning, .error])
    }
}
