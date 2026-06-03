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
        let resolvedState: AnalysisState = if let analysisState {
            analysisState
        } else if summary != nil, transcript != nil {
            .completed
        } else if transcript != nil {
            .transcribed
        } else {
            .pending
        }
        return VoiceNote(
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
            analysisState: resolvedState
        )
    }
}
