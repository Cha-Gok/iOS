import Foundation
import XCTest

@testable import Domain

final class AudioToSummaryUseCaseTests: XCTestCase {

    private var sttRepository: MockSTTRepository!
    private var summaryRepository: MockSummaryRepository!
    private var sut: DefaultAudioToSummaryUseCase!

    override func setUp() {
        super.setUp()
        sttRepository = MockSTTRepository()
        summaryRepository = MockSummaryRepository()
        sut = DefaultAudioToSummaryUseCase(
            sttRepository: sttRepository,
            summaryRepository: summaryRepository
        )
    }

    override func tearDown() {
        sut = nil
        summaryRepository = nil
        sttRepository = nil
        super.tearDown()
    }
}

// MARK: - 성공

extension AudioToSummaryUseCaseTests {

    func test_execute_모든과정이성공하면_결과를반환한다() async throws {
        // Given
        let audioURL = URL(fileURLWithPath: "/tmp/test.m4a")
        let transcript = Transcript.stub(text: "Hello world")
        let keywords = [Keyword.stub(word: "Hello")]
        let summary = Summary.stub(text: "A greeting")

        await sttRepository.setResult(.success(transcript))
        await sttRepository.expectTranscribe(callCount: 1, audioFileURL: audioURL)

        await summaryRepository.setResult(.success((keywords: keywords, summary: summary)))
        await summaryRepository.expectSummarize(callCount: 1, transcriptText: transcript.text)

        // When
        let result = try await sut.execute(audioFileURL: audioURL)

        // Then
        XCTAssertEqual(result.transcript.text, transcript.text)
        XCTAssertEqual(result.keywords.count, keywords.count)
        XCTAssertEqual(result.keywords.first?.word, keywords.first?.word)
        XCTAssertEqual(result.summary.text, summary.text)

        await sttRepository.verify()
        await summaryRepository.verify()
    }

    func test_execute_키워드가비어있어도_성공적으로결과를반환한다() async throws {
        // Given
        let audioURL = URL(fileURLWithPath: "/tmp/test.m4a")
        let transcript = Transcript.stub(text: "Hello")
        let keywords: [Keyword] = []
        let summary = Summary.stub(text: "Summary")

        await sttRepository.setResult(.success(transcript))
        await sttRepository.expectTranscribe(callCount: 1, audioFileURL: audioURL)

        await summaryRepository.setResult(.success((keywords: keywords, summary: summary)))
        await summaryRepository.expectSummarize(callCount: 1, transcriptText: transcript.text)

        // When
        let result = try await sut.execute(audioFileURL: audioURL)

        // Then
        XCTAssertTrue(result.keywords.isEmpty)

        await sttRepository.verify()
        await summaryRepository.verify()
    }
}

// MARK: - 실패

extension AudioToSummaryUseCaseTests {

    func test_execute_전사가실패하면_transcribeFailed에러를던진다() async {
        // Given
        let audioURL = URL(fileURLWithPath: "/tmp/test.m4a")
        await sttRepository.setResult(.failure(.transcribeFailed))
        await sttRepository.expectTranscribe(callCount: 1, audioFileURL: audioURL)
        await summaryRepository.expectSummarize(callCount: 0)

        // When
        do {
            _ = try await sut.execute(audioFileURL: audioURL)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .transcribeFailed(.transcribeFailed) = error else {
                return XCTFail("expected .transcribeFailed(.transcribeFailed), got \(error)")
            }
        }

        await sttRepository.verify()
        await summaryRepository.verify()
    }

    func test_execute_전사단계에서취소되면_transcribeFailed의cancelled에러를던진다() async {
        // Given
        let audioURL = URL(fileURLWithPath: "/tmp/test.m4a")
        await sttRepository.setResult(.failure(.cancelled))
        await sttRepository.expectTranscribe(callCount: 1, audioFileURL: audioURL)
        await summaryRepository.expectSummarize(callCount: 0)

        // When
        do {
            _ = try await sut.execute(audioFileURL: audioURL)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .transcribeFailed(.cancelled) = error else {
                return XCTFail("expected .transcribeFailed(.cancelled), got \(error)")
            }
        }

        await sttRepository.verify()
        await summaryRepository.verify()
    }

    func test_execute_전사중알수없는에러가발생하면_transcribeFailed의unknown에러를던진다() async {
        // Given
        let audioURL = URL(fileURLWithPath: "/tmp/test.m4a")
        struct DummyError: Error {}
        await sttRepository.setResult(.failure(.unknown(DummyError())))
        await sttRepository.expectTranscribe(callCount: 1, audioFileURL: audioURL)
        await summaryRepository.expectSummarize(callCount: 0)

        // When
        do {
            _ = try await sut.execute(audioFileURL: audioURL)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .transcribeFailed(.unknown(let error)) = error else {
                return XCTFail("expected .transcribeFailed(.unknown), got \(error)")
            }
            XCTAssertTrue(error is DummyError)
        }

        await sttRepository.verify()
        await summaryRepository.verify()
    }

    func test_execute_요약이실패하면_summarizeFailed에러를던진다() async {
        // Given
        let audioURL = URL(fileURLWithPath: "/tmp/test.m4a")
        let transcript = Transcript.stub(text: "Hello")
        await sttRepository.setResult(.success(transcript))
        await sttRepository.expectTranscribe(callCount: 1, audioFileURL: audioURL)

        await summaryRepository.setResult(.failure(.summarizeFailed))
        await summaryRepository.expectSummarize(callCount: 1, transcriptText: transcript.text)

        // When
        do {
            _ = try await sut.execute(audioFileURL: audioURL)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .summarizeFailed(.summarizeFailed) = error else {
                return XCTFail("expected .summarizeFailed(.summarizeFailed), got \(error)")
            }
        }

        await sttRepository.verify()
        await summaryRepository.verify()
    }

    func test_execute_요약단계에서취소되면_summarizeFailed의cancelled에러를던진다() async {
        // Given
        let audioURL = URL(fileURLWithPath: "/tmp/test.m4a")
        let transcript = Transcript.stub()
        await sttRepository.setResult(.success(transcript))
        await sttRepository.expectTranscribe(callCount: 1, audioFileURL: audioURL)

        await summaryRepository.setResult(.failure(.cancelled))
        await summaryRepository.expectSummarize(callCount: 1, transcriptText: transcript.text)

        // When
        do {
            _ = try await sut.execute(audioFileURL: audioURL)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .summarizeFailed(.cancelled) = error else {
                return XCTFail("expected .summarizeFailed(.cancelled), got \(error)")
            }
        }

        await sttRepository.verify()
        await summaryRepository.verify()
    }

    func test_execute_요약중알수없는에러가발생하면_summarizeFailed의unknown에러를던진다() async {
        // Given
        let audioURL = URL(fileURLWithPath: "/tmp/test.m4a")
        struct DummyError: Error {}
        let transcript = Transcript.stub()
        await sttRepository.setResult(.success(transcript))
        await sttRepository.expectTranscribe(callCount: 1, audioFileURL: audioURL)

        await summaryRepository.setResult(.failure(.unknown(DummyError())))
        await summaryRepository.expectSummarize(callCount: 1, transcriptText: transcript.text)

        // When
        do {
            _ = try await sut.execute(audioFileURL: audioURL)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .summarizeFailed(.unknown(let error)) = error else {
                return XCTFail("expected .summarizeFailed(.unknown), got \(error)")
            }
            XCTAssertTrue(error is DummyError)
        }

        await sttRepository.verify()
        await summaryRepository.verify()
    }
}

// MARK: - Task 취소

extension AudioToSummaryUseCaseTests {

    func test_execute_지점1_실행전에태스크가취소되면_cancelled에러를던진다() async {
        guard let sut else {
            return XCTFail("sut가 setup되지 않았습니다.")
        }
        // Given
        let audioURL = URL(fileURLWithPath: "/tmp/test.m4a")
        await sttRepository.expectTranscribe(callCount: 0)
        await summaryRepository.expectSummarize(callCount: 0)

        // When
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.execute(audioFileURL: audioURL)
        }

        // Then
        do {
            _ = try await task.value
            XCTFail("취소 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? AudioToSummaryUseCaseError else {
                return XCTFail("expected .cancelled, got \(error)")
            }
        }

        await sttRepository.verify()
        await summaryRepository.verify()
    }
}
