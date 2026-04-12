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

    func voiceNoteDateText(createdAt: Date, updatedAt: Date) -> String {
        let referenceDate = max(createdAt, updatedAt)
        return Self.voiceNoteDateText(referenceDate: referenceDate, now: self)
    }

    func voiceNoteDay(createdAt: Date, updatedAt: Date, duration: Double) -> String {
        let dateText = voiceNoteDateText(createdAt: createdAt, updatedAt: updatedAt)
        let durationText = duration.koreanDurationString
        return "\(dateText) · \(durationText)"
    }
}

// MARK: VoiceNote 시간 표기 확장

private extension Date {
    static func voiceNoteDateText(referenceDate: Date, now: Date) -> String {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ko_KR")

        let elapsed = now.timeIntervalSince(referenceDate)
        if elapsed >= 0, calendar.isDate(referenceDate, equalTo: now, toGranularity: .day) {
            if elapsed < 60 { return "방금 전" }
            if elapsed < 3600 { return "\(Int(elapsed / 60))분 전" }
            return "\(Int(elapsed / 3600))시간 전"
        }

        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now.addingTimeInterval(-31_536_000)
        if referenceDate < oneYearAgo {
            return referenceDate.toString(format: "yyyy.MM.dd")
        }

        return referenceDate.toString(format: "M월 d일 a h:mm")
    }
}
