@testable import Domain
import Foundation
import XCTest

public actor MockDefaultMLXSummaryRepository: SummaryRepository {
    public init() {}

    private var summarizeResult: Result<(keywords: [Keyword], summary: Summary), SummaryRepositoryError>?

    private var actualSummarizeCallCount = 0
    private var expectedSummarizeCallCount: Int?

    public func setSummarizeResult(_ result: Result<(keywords: [Keyword], summary: Summary), SummaryRepositoryError>) {
        summarizeResult = result
    }

    public func expectSummarize(callCount: Int) {
        expectedSummarizeCallCount = callCount
    }

    public func verify(file: StaticString = #filePath, line: UInt = #line) {
        assertCount(actualSummarizeCallCount, expectedSummarizeCallCount, "summarize", file, line)
    }

    private func assertCount(
        _ actual: Int,
        _ expected: Int?,
        _ label: String,
        _ file: StaticString,
        _ line: UInt
    ) {
        guard let expected else { return }
        XCTAssertEqual(actual, expected, "\(label) 호출 횟수 불일치", file: file, line: line)
    }

    public func summarize(
        transcript: Transcript,
        language: Language
    ) async throws(SummaryRepositoryError) -> (keywords: [Keyword], summary: Summary) {
        if Task.isCancelled { throw .cancelled }
        actualSummarizeCallCount += 1

        switch summarizeResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockDefaultMLXSummaryRepository.summarizeResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }
}
