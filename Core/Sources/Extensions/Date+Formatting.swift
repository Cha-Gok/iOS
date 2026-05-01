import Foundation

public extension Date {
    var yyyyMMddHHmmssString: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        return String(
            format: "%04d%02d%02d%02d%02d%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0,
            components.hour ?? 0,
            components.minute ?? 0,
            components.second ?? 0
        )
    }

    func toString(format: String, localeIdentifier: String = "ko_KR") -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.timeZone = TimeZone.autoupdatingCurrent
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
