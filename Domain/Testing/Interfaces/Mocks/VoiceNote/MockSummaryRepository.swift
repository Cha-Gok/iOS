@testable import Domain
import Foundation
import XCTest

public actor MockSummaryRepository: SummaryRepository {
    public init() {}

    private var result: Result<(keywords: [Keyword], summary: Summary), SummaryRepositoryError>?

    private var actualCallCount = 0
    private var actualTranscript: Transcript?

    private var expectedCallCount: Int?
    private var expectedTranscriptText: String?

    public func setResult(
        _ result: Result<(keywords: [Keyword], summary: Summary), SummaryRepositoryError>
    ) {
        self.result = result
    }

    public func expectSummarize(callCount: Int, transcriptText: String? = nil) {
        expectedCallCount = callCount
        expectedTranscriptText = transcriptText
    }

    public func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedCallCount {
            XCTAssertEqual(actualCallCount, expected, "요약 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
        if let expectedText = expectedTranscriptText {
            XCTAssertEqual(
                actualTranscript?.text, expectedText, "요약 텍스트 내용이 일치하지 않습니다.", file: file,
                line: line
            )
        }
    }

    public func summarize(transcript: Transcript, language: Language) async throws(SummaryRepositoryError) -> (
        keywords: [Keyword], summary: Summary
    ) {
        actualCallCount += 1
        actualTranscript = transcript

        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockSummaryRepository.result 가 설정되지 않았습니다.")
            throw .unknown(
                NSError(domain: "MockSummaryRepository.result", code: -1)
            )
        }
    }
}
