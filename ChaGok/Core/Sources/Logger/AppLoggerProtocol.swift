import Foundation

/// - Parameters:
///   - level: 로그 레벨
///   - message: 로그 메시지
///   - file: 파일 경로
///   - function: 함수 이름
///   - line: 줄 번호
public protocol AppLoggerProtocol {
    static func log(_ level: LogLevel, message: String, file: String, function: String, line: Int)
}

/// - Parameters:
///   - message: 로그 메시지
///   - file: 파일 경로
///   - function: 함수 이름
///   - line: 줄 번호
public extension AppLoggerProtocol {
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        Self.log(.debug, message: message, file: file, function: function, line: line)
    }

    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        Self.log(.info, message: message, file: file, function: function, line: line)
    }

    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        Self.log(.warning, message: message, file: file, function: function, line: line)
    }

    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        Self.log(.error, message: message, file: file, function: function, line: line)
    }

    static func error(_ error: Swift.Error, file: String = #file, function: String = #function, line: Int = #line) {
        Self.log(.error, message: String(describing: error), file: file, function: function, line: line)
    }
}
