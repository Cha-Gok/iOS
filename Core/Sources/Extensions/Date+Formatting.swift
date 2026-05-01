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

        let calendar = Calendar.current
        if calendar.isDate(referenceDate, inSameDayAs: now) {
            return "오늘"
        }

        let startOfReference = calendar.startOfDay(for: referenceDate)
        let startOfNow = calendar.startOfDay(for: now)
        let components = calendar.dateComponents([.day], from: startOfReference, to: startOfNow)

        if let day = components.day, day > 0, day <= 7 {
            return "\(day)일 전"
        }

        return referenceDate.toString(format: "yyyy.MM.dd")
    }
}
