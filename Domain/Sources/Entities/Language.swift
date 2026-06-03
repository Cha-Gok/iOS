import Foundation

public enum Language: String, CaseIterable, Sendable {
    case ko = "Korean"
    case en = "English"

    /// BCP-47 locale identifier. `Locale` / `SFSpeechRecognizer` 등 Foundation·플랫폼 API에 전달하는 용도.
    public var localeIdentifier: String {
        switch self {
        case .ko: return "ko-KR"
        case .en: return "en-US"
        }
    }
}
