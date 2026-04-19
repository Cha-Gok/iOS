import Core
import Domain
import Foundation

extension TranscriptSection {
    /// "MM:SS" (또는 "HH:MM:SS") 포맷 타임스탬프
    var formattedTimestamp: String {
        timestamp.durationString
    }
}
