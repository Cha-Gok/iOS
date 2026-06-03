import Foundation

/// 전사 섹션 — 시작 타임스탬프를 기준으로 묶인 스크립트 문단
public struct TranscriptSection: Sendable, Hashable, Codable {
    /// 섹션 시작 시간 (초)
    public let timestamp: TimeInterval
    /// 섹션 본문 텍스트
    public let text: String

    public init(timestamp: TimeInterval, text: String) {
        self.timestamp = timestamp
        self.text = text
    }
}
