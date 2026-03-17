@testable import Core
import Foundation

enum MockLogger: AppLoggerProtocol {
    nonisolated(unsafe) static var recordedLogs: [(level: LogLevel, message: String)] = []

    static func log(_ level: LogLevel, message: String, file: String, function: String, line: Int) {
        recordedLogs.append((level, message))
    }

    static func reset() {
        recordedLogs = []
    }
}
