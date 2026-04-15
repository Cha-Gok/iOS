@testable import Domain
import Core
import DomainTesting
import XCTest

final class AudioToSummaryUseCaseTest: XCTestCase {}

// MARK: - 성공 케이스

extension AudioToSummaryUseCaseTest {
    func test_정상상태_음성메모요약요청시_STT및요약결과를포함한객체를반환한다() async throws {
        let sttRepository = MockSTTRepository()
        let summaryRepository = MockSummaryRepository()
        let sut = DefaultAudioToSummaryUseCase(
            sttRepository: sttRepository,
            summaryRepository: summaryRepository
        )

        // Given
        let audioFilePath = "VoiceRecords/test.m4a"
        let expectedTranscript = Transcript.stub()
        let expectedSummary = Summary.stub()
        let expectedKeywords = [Keyword.stub()]

        await sttRepository.setResult(.success(expectedTranscript))
        await sttRepository.expectTranscribe(callCount: 1, audioFilePath: audioFilePath)

        await summaryRepository.setResult(.success((expectedKeywords, expectedSummary)))
        await summaryRepository.expectSummarize(
            callCount: 1, transcriptText: expectedTranscript.text
        )

        // When
        let result = try await sut.execute(audioFilePath: audioFilePath, language: .ko)

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
        let sttRepository = MockSTTRepository()
        let summaryRepository = MockSummaryRepository()
        let sut = DefaultAudioToSummaryUseCase(
            sttRepository: sttRepository,
            summaryRepository: summaryRepository
        )

        // Given
        let audioFilePath = "VoiceRecords/test.m4a"

        await sttRepository.setResult(.failure(.transcribeFailed))
        await sttRepository.expectTranscribe(callCount: 1, audioFilePath: audioFilePath)
        await summaryRepository.expectSummarize(callCount: 0)

        // When & Then
        do {
            _ = try await sut.execute(audioFilePath: audioFilePath, language: .ko)
            XCTFail("AudioToSummaryUseCaseError.transcribeFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .transcribeFailed = error else {
                return XCTFail(
                    "예상한 에러는 AudioToSummaryUseCaseError.transcribeFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
        await sttRepository.verify()
        await summaryRepository.verify()
    }

    func test_요약실패상태_음성메모요약요청시_summarizeFailed에러를던진다() async {
        let sttRepository = MockSTTRepository()
        let summaryRepository = MockSummaryRepository()
        let sut = DefaultAudioToSummaryUseCase(
            sttRepository: sttRepository,
            summaryRepository: summaryRepository
        )

        // Given
        let audioFilePath = "VoiceRecords/test.m4a"
        let expectedTranscript = Transcript.stub()

        await sttRepository.setResult(.success(expectedTranscript))
        await sttRepository.expectTranscribe(callCount: 1, audioFilePath: audioFilePath)

        await summaryRepository.setResult(.failure(.summarizeFailed))
        await summaryRepository.expectSummarize(
            callCount: 1, transcriptText: expectedTranscript.text
        )

        // When & Then
        do {
            _ = try await sut.execute(audioFilePath: audioFilePath, language: .ko)
            XCTFail("AudioToSummaryUseCaseError.summarizeFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .summarizeFailed = error else {
                return XCTFail(
                    "예상한 에러는 AudioToSummaryUseCaseError.summarizeFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
        await sttRepository.verify()
        await summaryRepository.verify()
    }

    func test_알수없는에러발생상태_음성메모요약요청시_unknown에러를던진다() async {
        let sttRepository = MockSTTRepository()
        let summaryRepository = MockSummaryRepository()
        let sut = DefaultAudioToSummaryUseCase(
            sttRepository: sttRepository,
            summaryRepository: summaryRepository
        )

        // Given
        let audioFilePath = "VoiceRecords/test.m4a"
        struct DummyError: Error {}
        let expectedError = DummyError()

        await sttRepository.setResult(.failure(.unknown(expectedError)))
        await sttRepository.expectTranscribe(callCount: 1, audioFilePath: audioFilePath)

        // When & Then
        do {
            _ = try await sut.execute(audioFilePath: audioFilePath, language: .ko)
            XCTFail("AudioToSummaryUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let underlyingError) = error else {
                return XCTFail(
                    "예상한 에러는 AudioToSummaryUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
            XCTAssertTrue(underlyingError is DummyError)
        }
        await sttRepository.verify()
        await summaryRepository.verify()
    }
}

// MARK: - 취소 케이스

extension AudioToSummaryUseCaseTest {
    func test_작업취소상태_음성메모요약요청시_cancelled에러를던진다() async {
        let sttRepository = MockSTTRepository()
        let summaryRepository = MockSummaryRepository()
        let sut = DefaultAudioToSummaryUseCase(
            sttRepository: sttRepository,
            summaryRepository: summaryRepository
        )

        // Given
        let audioFilePath = "VoiceRecords/test.m4a"

        await sttRepository.setResult(.failure(.cancelled))
        await sttRepository.expectTranscribe(callCount: 1, audioFilePath: audioFilePath)

        // When & Then
        do {
            _ = try await sut.execute(audioFilePath: audioFilePath, language: .ko)
            XCTFail("AudioToSummaryUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error else {
                return XCTFail(
                    "예상한 에러는 AudioToSummaryUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
        await sttRepository.verify()
        await summaryRepository.verify()
    }

    func test_태스크이미취소상태_음성메모요약요청시_즉시cancelled에러를던진다() async {
        let sttRepository = MockSTTRepository()
        let summaryRepository = MockSummaryRepository()
        let sut = DefaultAudioToSummaryUseCase(
            sttRepository: sttRepository,
            summaryRepository: summaryRepository
        )

        // Given
        let audioFilePath = "VoiceRecords/test.m4a"

        await sttRepository.expectTranscribe(callCount: 0)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await sut.execute(audioFilePath: audioFilePath, language: .ko)
        }

        do {
            _ = try await task.value
            XCTFail("AudioToSummaryUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? AudioToSummaryUseCaseError else {
                return XCTFail(
                    "예상한 에러는 AudioToSummaryUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
        await sttRepository.verify()
        await summaryRepository.verify()
    }
}
