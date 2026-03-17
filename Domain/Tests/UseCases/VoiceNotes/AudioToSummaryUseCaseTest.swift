@testable import Domain
import XCTest

final class AudioToSummaryUseCaseTest: XCTestCase {
    typealias UseCaseError = AudioToSummaryUseCaseError
}

// MARK: - 성공 케이스

extension AudioToSummaryUseCaseTest {
    func test_정상상태_음성메모요약요청시_STT및요약결과를포함한객체를반환한다() async throws {
        // Given
        let audioURL = URL(fileURLWithPath: "/test.m4a")
        let expectedTranscript = Transcript.stub()
        let expectedSummary = Summary.stub()
        let expectedKeywords = [Keyword.stub()]

        let sttRepository = MockSTTRepository()
        let summaryRepository = MockSummaryRepository()

        await sttRepository.setResult(.success(expectedTranscript))
        await sttRepository.expectTranscribe(callCount: 1, audioFileURL: audioURL)

        await summaryRepository.setResult(.success((expectedKeywords, expectedSummary)))
        await summaryRepository.expectSummarize(callCount: 1, transcriptText: expectedTranscript.text)

        let useCase = DefaultAudioToSummaryUseCase(
            sttRepository: sttRepository,
            summaryRepository: summaryRepository
        )

        // When
        let result = try await useCase.execute(audioFileURL: audioURL)

        // Then
        XCTAssertEqual(result.transcript.text, expectedTranscript.text)
        XCTAssertEqual(result.summary.text, expectedSummary.text)
        XCTAssertEqual(result.keywords.count, expectedKeywords.count)
        if !result.keywords.isEmpty {
            XCTAssertEqual(result.keywords[0].word, expectedKeywords[0].word)
        }
        await sttRepository.verify()
        await summaryRepository.verify()
    }
}

// MARK: - 에러 케이스

extension AudioToSummaryUseCaseTest {
    func test_STT실패상태_음성메모요약요청시_transcribeFailed에러를던진다() async {
        // Given
        let audioURL = URL(fileURLWithPath: "/test.m4a")
        let sttRepository = MockSTTRepository()
        let summaryRepository = MockSummaryRepository()

        await sttRepository.setResult(.failure(.transcribeFailed))
        await sttRepository.expectTranscribe(callCount: 1, audioFileURL: audioURL)
        await summaryRepository.expectSummarize(callCount: 0)

        let useCase = DefaultAudioToSummaryUseCase(
            sttRepository: sttRepository,
            summaryRepository: summaryRepository
        )

        // When & Then
        do {
            _ = try await useCase.execute(audioFileURL: audioURL)
            XCTFail("STT 실패 시 .transcribeFailed 에러가 발생해야 합니다.")
        } catch UseCaseError.transcribeFailed {
            // Success
            await sttRepository.verify()
            await summaryRepository.verify()
        } catch {
            XCTFail("Expected .transcribeFailed, got \(error)")
        }
    }

    func test_요약실패상태_음성메모요약요청시_summarizeFailed에러를던진다() async {
        // Given
        let audioURL = URL(fileURLWithPath: "/test.m4a")
        let expectedTranscript = Transcript.stub()
        let sttRepository = MockSTTRepository()
        let summaryRepository = MockSummaryRepository()

        await sttRepository.setResult(.success(expectedTranscript))
        await sttRepository.expectTranscribe(callCount: 1, audioFileURL: audioURL)

        await summaryRepository.setResult(.failure(.summarizeFailed))
        await summaryRepository.expectSummarize(callCount: 1, transcriptText: expectedTranscript.text)

        let useCase = DefaultAudioToSummaryUseCase(
            sttRepository: sttRepository,
            summaryRepository: summaryRepository
        )

        // When & Then
        do {
            _ = try await useCase.execute(audioFileURL: audioURL)
            XCTFail("요약 실패 시 .summarizeFailed 에러가 발생해야 합니다.")
        } catch UseCaseError.summarizeFailed {
            // Success
            await sttRepository.verify()
            await summaryRepository.verify()
        } catch {
            XCTFail("Expected .summarizeFailed, got \(error)")
        }
    }

    func test_알수없는에러발생상태_음성메모요약요청시_unknown에러를던진다() async {
        // Given
        let audioURL = URL(fileURLWithPath: "/test.m4a")
        struct Dummy: Error {}
        let dummyError = Dummy()
        let sttRepository = MockSTTRepository()
        let summaryRepository = MockSummaryRepository()

        await sttRepository.setResult(.failure(.unknown(dummyError)))
        await sttRepository.expectTranscribe(callCount: 1, audioFileURL: audioURL)

        let useCase = DefaultAudioToSummaryUseCase(
            sttRepository: sttRepository,
            summaryRepository: summaryRepository
        )

        // When & Then
        do {
            _ = try await useCase.execute(audioFileURL: audioURL)
            XCTFail("알 수 없는 에러 발생 시 .unknown으로 래핑되어야 합니다.")
        } catch UseCaseError.unknown(let error) {
            XCTAssertTrue(error is STTRepositoryError)
            await sttRepository.verify()
            await summaryRepository.verify()
        } catch {
            XCTFail("Expected .unknown, got \(error)")
        }
    }
}

// MARK: - 취소 케이스

extension AudioToSummaryUseCaseTest {
    func test_작업취소상태_음성메모요약요청시_cancelled에러를던진다() async {
        // Given
        let audioURL = URL(fileURLWithPath: "/test.m4a")
        let sttRepository = MockSTTRepository()
        let summaryRepository = MockSummaryRepository()

        await sttRepository.setResult(.failure(.cancelled))
        await sttRepository.expectTranscribe(callCount: 1, audioFileURL: audioURL)

        let useCase = DefaultAudioToSummaryUseCase(
            sttRepository: sttRepository,
            summaryRepository: summaryRepository
        )

        // When & Then
        do {
            _ = try await useCase.execute(audioFileURL: audioURL)
            XCTFail("작업 취소 시 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
            await sttRepository.verify()
            await summaryRepository.verify()
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }

    func test_태스크이미취소상태_음성메모요약요청시_즉시cancelled에러를던진다() async {
        // Given
        let audioURL = URL(fileURLWithPath: "/test.m4a")
        let sttRepository = MockSTTRepository()
        let summaryRepository = MockSummaryRepository()

        await sttRepository.expectTranscribe(callCount: 0)

        let useCase = DefaultAudioToSummaryUseCase(
            sttRepository: sttRepository,
            summaryRepository: summaryRepository
        )

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await useCase.execute(audioFileURL: audioURL)
        }

        do {
            _ = try await task.value
            XCTFail("이미 취소된 태스크이므로 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
            await sttRepository.verify()
            await summaryRepository.verify()
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }
}
