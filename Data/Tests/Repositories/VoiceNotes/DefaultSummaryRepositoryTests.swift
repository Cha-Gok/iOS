@testable import Data
import Domain
import Foundation
import XCTest

final class DefaultSummaryRepositoryTests: XCTestCase {
    private var repository: DefaultSummaryRepository!
    private var mockService: MockSummaryService!

    override func setUp() {
        super.setUp()
        mockService = MockSummaryService()
        repository = DefaultSummaryRepository(service: mockService)
    }

    override func tearDown() {
        repository = nil
        mockService = nil
        super.tearDown()
    }

    func test_summarize_성공할_경우_도메인_엔티티로_변환하여_반환한다() async throws {
        // Given
        let transcript = Transcript(id: UUID(), text: "원본 텍스트입니다.")
        let language: Language = .ko
        let expectedKeywords = ["키워드1", "키워드2"]
        let expectedSummary = "요약된 텍스트입니다."

        await mockService.setResult(.success((keywords: expectedKeywords, summary: expectedSummary)))

        // When
        let (keywords, summary) = try await repository.summarize(transcript: transcript, language: language)

        // Then
        XCTAssertEqual(keywords.count, expectedKeywords.count)
        XCTAssertEqual(keywords[0].word, "키워드1")
        XCTAssertEqual(summary.text, expectedSummary)

        await mockService.verify(expectedCallCount: 1, expectedText: transcript.text, expectedLanguage: language)
    }

    func test_summarize_서비스가_실패할_경우_도메인_에러를_던진다() async {
        // Given
        let transcript = Transcript(id: UUID(), text: "원본 텍스트입니다.")
        let language: Language = .en
        await mockService.setResult(.failure(.summarizeFailed))

        // When & Then
        do {
            _ = try await repository.summarize(transcript: transcript, language: language)
            XCTFail("에러가 발생해야 합니다.")
        } catch {}

        await mockService.verify(expectedCallCount: 1, expectedLanguage: language)
    }

    func test_summarize_취소될_경우_cancelled_에러를_던진다() async {
        // Given
        let transcript = Transcript(id: UUID(), text: "원본 텍스트입니다.")
        let language: Language = .ko
        await mockService.setResult(.failure(.cancelled))

        // When & Then
        do {
            _ = try await repository.summarize(transcript: transcript, language: language)
            XCTFail("에러가 발생해야 합니다.")
        } catch {}
    }
}
