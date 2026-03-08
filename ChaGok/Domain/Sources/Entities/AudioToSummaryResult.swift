import Foundation

public struct AudioToSummaryResult: Sendable {
    public let transcript: Transcript
    public let keywords: [Keyword]
    public let summary: Summary

    public init(
        transcript: Transcript,
        keywords: [Keyword],
        summary: Summary
    ) {
        self.transcript = transcript
        self.keywords = keywords
        self.summary = summary
    }
}
