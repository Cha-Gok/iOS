import Foundation

public enum Language: String, CaseIterable, Sendable {
    case ko
    case en

    public var text: String {
        switch self {
        case .ko:
            return "한국어 (기본설정)"
        case .en:
            return "영어"
        }
    }
}
