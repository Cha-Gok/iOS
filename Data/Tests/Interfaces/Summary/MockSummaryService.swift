@testable import Data
import Domain
import XCTest

actor MockSummaryService: SummaryService {
    private var result: Result<(keywords: [String], summary: String), SummaryServiceError>?

    private var actualCallCount = 0
    private var actualText: String?
    private var actualLanguage: Language?

    func setResult(_ result: Result<(keywords: [String], summary: String), SummaryServiceError>) {
        self.result = result
    }

    func summarize(
        text: String,
        language: Language
    ) async throws(SummaryServiceError) -> (keywords: [String], summary: String) {
        actualCallCount += 1
        actualText = text
        actualLanguage = language

        switch result {
        case .success(let model):
            return model
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockSummaryService.result 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockSummaryService", code: -1))
        }
    }

    func verify(
        expectedCallCount: Int? = nil,
        expectedText: String? = nil,
        expectedLanguage: Language? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if let expected = expectedCallCount {
            XCTAssertEqual(actualCallCount, expected, "호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
        if let expectedText {
            XCTAssertEqual(actualText, expectedText, "입력 텍스트가 일치하지 않습니다.", file: file, line: line)
        }
        if let expectedLanguage {
            XCTAssertEqual(actualLanguage, expectedLanguage, "입력 언어가 일치하지 않습니다.", file: file, line: line)
        }
    }
}
