import Domain
import Foundation

public struct KeyPoint {
    let number: Int
    let text: String
}

public struct ScriptSection {
    let timestamp: String
    let paragraphs: [String]
}

public final class VoiceNoteViewModel {
    public let voiceNote: VoiceNote

    // MARK: - Mapped Properties

    public var title: String {
        voiceNote.title
    }

    public var folderName: String = ""

    public var metadataText1: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd · a HH:mm"
        let created = formatter.string(from: voiceNote.createdAt)
        guard voiceNote.createdAt != voiceNote.updatedAt else { return created }
        let updatedFormatter = DateFormatter()
        updatedFormatter.locale = Locale(identifier: "ko_KR")
        updatedFormatter.dateFormat = "yyyy.MM.dd"
        return "\(created) (\(updatedFormatter.string(from: voiceNote.updatedAt)) 수정됨)"
    }

    public var metadataText2: String {
        let total = Int(voiceNote.voiceRecord.duration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 { return "\(hours)시간 \(minutes)분 \(seconds)초" }
        if minutes > 0 { return "\(minutes)분 \(seconds)초" }
        return "\(seconds)초"
    }

    public var keywords: [String] {
        voiceNote.keywords.map(\.word)
    }

    public var keyPoints: [KeyPoint] = []
    public var scriptSections: [ScriptSection] = []

    // MARK: - Init

    public init(voiceNote: VoiceNote) {
        self.voiceNote = voiceNote
    }
}
