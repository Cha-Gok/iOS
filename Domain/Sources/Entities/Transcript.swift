import Foundation

public struct Transcript: Sendable, Identifiable, Hashable {
    public let id: UUID
    public let createdAt: Date
    public let text: String
    /// 단어 단위 타이밍 세그먼트. 레거시 데이터는 빈 배열.
    public let segments: [TranscriptSegment]

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date.now,
        text: String,
        segments: [TranscriptSegment] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.text = text
        self.segments = segments
    }
}
