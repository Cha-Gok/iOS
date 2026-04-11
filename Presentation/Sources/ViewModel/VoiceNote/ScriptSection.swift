import Core
import Foundation

public struct ScriptSection: Hashable {
    /// 섹션 시작 시간 (초)
    let timestamp: TimeInterval
    let paragraphs: [String]

    /// "MM:SS" (또는 "HH:MM:SS") 포맷 타임스탬프
    var formattedTimestamp: String {
        timestamp.durationString
    }
}
