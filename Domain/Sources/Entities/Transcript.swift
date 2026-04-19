import Foundation

public struct Transcript: Sendable, Identifiable, Hashable {
    public let id: UUID
    public let createdAt: Date
    /// 타임스탬프 기반으로 묶인 스크립트 섹션
    public let sections: [TranscriptSection]

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date.now,
        sections: [TranscriptSection] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.sections = sections
    }
}
