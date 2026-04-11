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
}
