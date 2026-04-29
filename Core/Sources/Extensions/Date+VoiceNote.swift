import Foundation

// MARK: - VoiceNote 관련 Date 확장

public extension Date {
    func voiceNoteDay(createdAt: Date, updatedAt: Date, duration: Double) -> String {
        let dateText = voiceNoteDateText(createdAt: createdAt, updatedAt: updatedAt)
        let durationText = duration.koreanDurationString

        if Int(createdAt.timeIntervalSince1970) != Int(updatedAt.timeIntervalSince1970) {
            let updateText = Self.updatedDateText(updatedAt: updatedAt, now: self)
            return "\(dateText) (\(updateText)) · \(durationText)"
        }

        return "\(dateText) · \(durationText)"
    }

    func trashVoiceNoteDay(createdAt: Date, updatedAt: Date, deletedAt: Date?) -> String {
        let referenceDate = max(createdAt, updatedAt)
        let createdTimeText = referenceDate.toString(format: "a h:mm")

        guard let deletedAt else {
            return createdTimeText
        }

        let deletedText = Self.relativeDateText(referenceDate: deletedAt, now: self)
        return "\(createdTimeText) · \(deletedText) 삭제"
    }

    func searchVoiceNoteDay(createdAt: Date, updatedAt: Date, duration: Double, folderName: String) -> String {
        let frontText = voiceNoteDay(createdAt: createdAt, updatedAt: updatedAt, duration: duration)
        return frontText + " · " + folderName
    }

    internal func voiceNoteDateText(createdAt: Date, updatedAt: Date) -> String {
        let referenceDate = max(createdAt, updatedAt)
        return Self.voiceNoteMainDateText(referenceDate: referenceDate, now: self)
    }

    private static func voiceNoteMainDateText(referenceDate: Date, now: Date) -> String {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ko_KR")

        let elapsed = now.timeIntervalSince(referenceDate)
        if elapsed >= 0, calendar.isDate(referenceDate, equalTo: now, toGranularity: .day) {
            if elapsed < 60 { return "방금 전" }
            if elapsed < 3600 { return "\(Int(elapsed / 60))분 전" }
            return referenceDate.toString(format: "a h:mm")
        }

        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now.addingTimeInterval(-31_536_000)
        if referenceDate < oneYearAgo {
            return referenceDate.toString(format: "yyyy.MM.dd")
        }

        return referenceDate.toString(format: "M월 d일 a h:mm")
    }

    private static func updatedDateText(updatedAt: Date, now: Date) -> String {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ko_KR")

        if calendar.isDate(updatedAt, equalTo: now, toGranularity: .day) {
            return "오늘 수정됨"
        }

        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now.addingTimeInterval(-31_536_000)
        if updatedAt < oneYearAgo {
            return "\(updatedAt.toString(format: "yyyy.MM.dd")) 수정됨"
        }

        return "\(updatedAt.toString(format: "M월 d일")) 수정됨"
    }
}
