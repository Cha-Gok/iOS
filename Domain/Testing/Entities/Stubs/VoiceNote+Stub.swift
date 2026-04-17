@testable import Domain
import Foundation

public extension VoiceNote {
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
        deletedAt: Date? = nil,
        analysisState: AnalysisState? = nil
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
            deletedAt: deletedAt,
            analysisState: analysisState
        )
    }
}
