@testable import Data
import Domain
import Foundation
import XCTest

final class DefaultSummaryRepositoryTest: XCTestCase {}

// MARK: - 성공 케이스

extension DefaultSummaryRepositoryTest {
    func test_정상상태_요약시_도메인엔티티로변환하여반환한다() async throws {
        let mockService = MockSummaryService()
        let sut = DefaultSummaryRepository(service: mockService)

        // Given
        let transcript = Transcript(id: UUID(), text: "원본 텍스트입니다.")
        let language: Language = .ko
        let expectedKeywords = ["키워드1", "키워드2"]
        let expectedSummaryText = "요약된 텍스트입니다."
        await mockService.setResult(.success((keywords: expectedKeywords, summary: expectedSummaryText)))

        // When
        let (keywords, summary) = try await sut.summarize(transcript: transcript, language: language)

        // Then
        XCTAssertEqual(keywords.count, expectedKeywords.count)
        XCTAssertEqual(keywords[0].word, "키워드1")
        XCTAssertEqual(summary.text, expectedSummaryText)
        await mockService.verify(expectedCallCount: 1, expectedText: transcript.text, expectedLanguage: language)
    }
}

// MARK: - 에러 케이스

extension DefaultSummaryRepositoryTest {
    func test_서비스실패상태_요약시_summarizeFailed에러를던진다() async {
        let mockService = MockSummaryService()
        let sut = DefaultSummaryRepository(service: mockService)

        // Given
        let transcript = Transcript(id: UUID(), text: "원본 텍스트입니다.")
        let language: Language = .en
        await mockService.setResult(.failure(.summarizeFailed))

        // When & Then
        do {
            _ = try await sut.summarize(transcript: transcript, language: language)
            XCTFail("SummaryRepositoryError.summarizeFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .summarizeFailed = error else {
                return XCTFail("예상한 에러는 SummaryRepositoryError.summarizeFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await mockService.verify(expectedCallCount: 1, expectedLanguage: language)
    }
}

// MARK: - 취소 케이스

extension DefaultSummaryRepositoryTest {
    func test_태스크취소상태_요약시_cancelled에러를던진다() async throws {
        let mockService = MockSummaryService()
        let sut = DefaultSummaryRepository(service: mockService)

        // Given (서비스 호출 전에 Task가 취소되므로 result 설정 불필요)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.summarize(transcript: Transcript(id: UUID(), text: "텍스트"), language: .ko)
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("SummaryRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? SummaryRepositoryError else {
                return XCTFail("예상한 에러는 SummaryRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await mockService.verify(expectedCallCount: 0)
    }
}
