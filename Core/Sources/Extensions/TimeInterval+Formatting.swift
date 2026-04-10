import Foundation

public extension TimeInterval {
    /// `MM:SS` 또는 `HH:MM:SS` 형식의 문자열로 변환합니다.
    var durationString: String {
        let duration = Duration.seconds(max(self, 0))
        let pattern: Duration.TimeFormatStyle.Pattern = self >= 3600 ? .hourMinuteSecond : .minuteSecond
        return duration.formatted(.time(pattern: pattern))
    }
}
