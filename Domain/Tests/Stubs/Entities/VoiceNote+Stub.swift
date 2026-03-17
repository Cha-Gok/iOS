@testable import Domain
import Foundation

extension VoiceNote {
    static func stub(
        id: UUID = UUID(),
        title: String = "Test Voice Note",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        folderID: UUID = UUID(),
        voiceRecord: VoiceRecord = .stub(),
        keywords: [Keyword] = [],
        transcript: Transcript? = nil,
        summary: Summary? = nil,
        deletedAt: Date? = nil
    ) -> VoiceNote {
        VoiceNote(
            id: id,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
            folderID: folderID,
            voiceRecord: voiceRecord,
            keywords: keywords,
            transcript: transcript,
            summary: summary,
            deletedAt: deletedAt
        )
    }
}
