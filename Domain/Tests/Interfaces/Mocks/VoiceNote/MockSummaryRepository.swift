@testable import Domain
import Foundation
import XCTest

actor MockSummaryRepository: SummaryRepository {
    private var result: Result<(keywords: [Keyword], summary: Summary), SummaryRepositoryError>?

    private var actualCallCount = 0
    private var actualTranscript: Transcript?

    private var expectedCallCount: Int?
    private var expectedTranscriptText: String?

    func setResult(
        _ result: Result<(keywords: [Keyword], summary: Summary), SummaryRepositoryError>
    ) {
        self.result = result
    }

    func expectSummarize(callCount: Int, transcriptText: String? = nil) {
        expectedCallCount = callCount
        expectedTranscriptText = transcriptText
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
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

    func summarize(transcript: Transcript, language: Language) async throws(SummaryRepositoryError) -> (
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
