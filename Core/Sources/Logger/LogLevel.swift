import Foundation

public enum LogLevel: Int {
    case debug
    case info
    case warning
    case error

    public var symbol: String {
        switch self {
        case .debug: "🔍"
        case .info: "ℹ️"
        case .warning: "⚠️"
        case .error: "❌"
        }
    }
}

extension LogLevel: CaseIterable {}
extension LogLevel: Sendable {}
