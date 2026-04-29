import Foundation

public extension Date {
    var yyyyMMddHHmmssString: String {
        formatted(
            Date.VerbatimFormatStyle(
                format: "\(year: .defaultDigits)\(month: .twoDigits)\(day: .twoDigits)\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased))\(minute: .twoDigits)\(second: .twoDigits)",
                timeZone: .current,
                calendar: .current
            )
        )
    }

    func toString(format: String, localeIdentifier: String = "ko_KR") -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    static func relativeDateText(referenceDate: Date, now: Date) -> String {
        let elapsed = now.timeIntervalSince(referenceDate)
        if elapsed < 0 {
            return referenceDate.toString(format: "M월 d일 a h:mm")
        }

        if elapsed < 60 { return "방금 전" }
        if elapsed < 3600 { return "\(Int(elapsed / 60))분 전" }
        if elapsed < 86400 { return "\(Int(elapsed / 3600))시간 전" }
        if elapsed < 2_592_000 { return "\(Int(elapsed / 86400))일 전" }
        if elapsed < 31_536_000 { return "\(Int(elapsed / 2_592_000))개월 전" }

        return referenceDate.toString(format: "yyyy.MM.dd")
    }
}
