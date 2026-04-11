import Foundation

public struct ScriptSection: Hashable {
    /// 섹션 시작 시간 (초)
    let timestamp: TimeInterval
    let paragraphs: [String]

    /// "MM:SS" 포맷 타임스탬프
    var formattedTimestamp: String {
        let totalSeconds = Int(timestamp)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
