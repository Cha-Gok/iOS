@testable import Domain
import Foundation

public extension Transcript {
    static func stub(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        sections: [TranscriptSection] = [TranscriptSection(timestamp: 0, text: "mock transcript")]
    ) -> Transcript {
        Transcript(id: id, createdAt: createdAt, updatedAt: updatedAt, sections: sections)
    }

    static func stub(text: String) -> Transcript {
        Transcript(sections: [TranscriptSection(timestamp: 0, text: text)])
    }
}
