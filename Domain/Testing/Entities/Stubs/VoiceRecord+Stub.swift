@testable import Domain
import Foundation

public extension VoiceRecord {
    static func stub(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        audioFilePath: String = "VoiceRecords/test.m4a",
        duration: Double = 60.0
    ) -> VoiceRecord {
        VoiceRecord(
            id: id,
            createdAt: createdAt,
            audioFilePath: audioFilePath,
            duration: duration
        )
    }
}
