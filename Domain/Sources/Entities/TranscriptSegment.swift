import Foundation

/// 전사 세그먼트 — 단어 단위의 타이밍 정보를 포함
public struct TranscriptSegment: Sendable, Hashable, Codable {
    /// 해당 세그먼트의 단어 텍스트
    public let substring: String
    /// 오디오 내 시작 시간 (초)
    public let timestamp: TimeInterval
    /// 발화 지속 시간 (초)
    public let duration: TimeInterval

    public init(
        substring: String,
        timestamp: TimeInterval,
        duration: TimeInterval
    ) {
        self.substring = substring
        self.timestamp = timestamp
        self.duration = duration
    }
}
