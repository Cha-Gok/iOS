@testable import Domain
import Foundation

public extension VoiceRecord {
    static func stub(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        audioFilePath: URL = URL(fileURLWithPath: "/test/path.m4a"),
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
