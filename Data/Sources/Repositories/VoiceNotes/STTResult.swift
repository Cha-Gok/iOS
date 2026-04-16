import Foundation

/// STT 전사 결과 — 텍스트와 세그먼트별 타이밍 정보를 포함
public struct STTResult: Sendable {
    /// 전체 전사 텍스트
    public let text: String
    /// 단어 단위 세그먼트 (단어, 시작 시간, 지속 시간)
    public let segments: [Segment]

    public struct Segment: Sendable {
        public let substring: String
        public let timestamp: TimeInterval
        public let duration: TimeInterval

        public init(substring: String, timestamp: TimeInterval, duration: TimeInterval) {
            self.substring = substring
            self.timestamp = timestamp
            self.duration = duration
        }
    }

    public init(text: String, segments: [Segment]) {
        self.text = text
        self.segments = segments
    }
}
