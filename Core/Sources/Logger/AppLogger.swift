import Foundation
import os.log

public enum AppLogger: AppLoggerProtocol, Sendable {
    private static let subsystem = "com.yongms.ChaGokChaGok"
    private static let category = "default"
    private static let osLog = OSLog(subsystem: subsystem, category: category)
    private static let minLevel: LogLevel = {
        #if DEBUG
            return .debug
        #else
            return .info
        #endif
    }()

    public static func log(
        _ level: LogLevel,
        message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard level.rawValue >= minLevel.rawValue else { return }

        let fileName = (file as NSString).lastPathComponent
        let logMessage = "\(level.symbol) [\(fileName):\(line) \(function)] \(message)"
        let type = level.osLogType

        os_log("%{public}@", log: osLog, type: type, logMessage)
    }
}

private extension LogLevel {
    var osLogType: OSLogType {
        switch self {
        case .debug: .debug
        case .info: .info
        case .warning: .default
        case .error: .error
        }
    }
}
