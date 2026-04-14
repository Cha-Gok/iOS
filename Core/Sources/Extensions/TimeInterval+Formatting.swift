import Foundation

public extension TimeInterval {
    /// `MM:SS` 또는 `HH:MM:SS` 형식의 문자열로 변환합니다.
    var durationString: String {
        let duration = Duration.seconds(max(self, 0))
        let pattern: Duration.TimeFormatStyle.Pattern = self >= 3600 ? .hourMinuteSecond : .minuteSecond
        return duration.formatted(.time(pattern: pattern))
    }

    var koreanDurationString: String {
        let total = Int(self)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        var parts: [String] = []
        if hours > 0 {
            parts.append("\(hours)시간")
        }
        if minutes > 0 {
            parts.append("\(minutes)분")
        }
        if seconds > 0 {
            parts.append("\(seconds)초")
        }

        if parts.isEmpty {
            return "0초"
        }

        return parts.joined(separator: " ")
    }
}
