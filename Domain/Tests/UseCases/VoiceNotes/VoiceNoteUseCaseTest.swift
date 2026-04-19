@testable import Domain
import Core
import DomainTesting
import XCTest

@MainActor
final class VoiceNoteUseCaseTest: XCTestCase {
    private struct SUT {
        let useCase: VoiceNoteUseCase
        let repository: MockVoiceNoteRepository
        let sttRepository: MockSTTRepository
        let summaryRepository: MockSummaryRepository
    }

    private func makeSUT() -> SUT {
        let repository = MockVoiceNoteRepository()
        let sttRepository = MockSTTRepository()
        let summaryRepository = MockSummaryRepository()
        let useCase = DefaultVoiceNoteUseCase(
            repository: repository,
            sttRepository: sttRepository,
            summaryRepository: summaryRepository
        )
        return SUT(
            useCase: useCase,
            repository: repository,
            sttRepository: sttRepository,
            summaryRepository: summaryRepository
        )
    }
}

// MARK: - Create

extension VoiceNoteUseCaseTest {
    func test_create_정상호출시_리포지토리를호출하고결과를반환한다() throws {
        let sut = makeSUT()
        let voiceRecord = VoiceRecord.stub()
        let expectedNote = VoiceNote.stub(voiceRecord: voiceRecord)

        sut.repository.setCreateResult(.success(expectedNote))
        sut.repository.expectCreate(callCount: 1)

        let result = try sut.useCase.create(voiceRecord)

        XCTAssertEqual(result.id, expectedNote.id)
        sut.repository.verify()
    }
}

// MARK: - Update

extension VoiceNoteUseCaseTest {
    func test_update_제목이비어있으면_invalidTitle에러를던진다() {
        let sut = makeSUT()
        let voiceNote = VoiceNote.stub(title: "")

        do {
            _ = try sut.useCase.update(voiceNote)
            XCTFail("에러가 발생해야 합니다.")
        } catch {
            guard case VoiceNoteUseCaseError.invalidTitle = error else {
                return XCTFail("잘못된 에러 타입: \(error)")
            }
        }
    }

    func test_update_정상호출시_리포지토리를호출하고결과를반환한다() throws {
        let sut = makeSUT()
        let voiceNote = VoiceNote.stub(title: "수정된 제목")
        sut.repository.setUpdateResult(.success(voiceNote))
        sut.repository.expectUpdate(callCount: 1)

        let result = try sut.useCase.update(voiceNote)

        XCTAssertEqual(result.title, "수정된 제목")
        sut.repository.verify()
    }
}

// MARK: - Fetch

extension VoiceNoteUseCaseTest {
    func test_fetchAllFromDefaultFolder_호출시_리포지토리를호출한다() throws {
        let sut = makeSUT()
        let expected = [VoiceNote.stub()]
        sut.repository.setFetchAllResult(.success(expected))
        sut.repository.expectFetchAllFromDefaultFolder(callCount: 1)

        let result = try sut.useCase.fetchAllFromDefaultFolder()

        XCTAssertEqual(result.count, 1)
        sut.repository.verify()
    }

    func test_fetchRecent_호출시_리포지토리를호출한다() throws {
        let sut = makeSUT()
        let expected = [VoiceNote.stub()]
        sut.repository.setFetchRecentResult(.success(expected))
        sut.repository.expectFetchRecent(callCount: 1)

        let result = try sut.useCase.fetchRecent(limit: 5)

        XCTAssertEqual(result.count, 1)
        sut.repository.verify()
    }
}

// MARK: - Transcribe

extension VoiceNoteUseCaseTest {
    func test_transcribe_정상호출시_전사본을반환한다() async throws {
        let sut = makeSUT()
        let audioPath = "test.m4a"
        let transcript = Transcript.stub(text: "전사본")

        await sut.sttRepository.setResult(.success(transcript))
        await sut.sttRepository.expectTranscribe(callCount: 1, audioFilePath: audioPath)

        let result = try await sut.useCase.transcribe(audioFilePath: audioPath)

        XCTAssertEqual(result.sections.first?.text, "전사본")
        await sut.sttRepository.verify()
    }

    func test_transcribe_STT실패시_analysisFailed에러를던진다() async {
        let sut = makeSUT()
        await sut.sttRepository.setResult(.failure(.transcribeFailed))

        do {
            _ = try await sut.useCase.transcribe(audioFilePath: "test.m4a")
            XCTFail("에러가 발생해야 합니다.")
        } catch {
            guard case VoiceNoteUseCaseError.analysisFailed = error else {
                return XCTFail("잘못된 에러 타입: \(error)")
            }
        }
    }
}

// MARK: - Summarize

extension VoiceNoteUseCaseTest {
    func test_summarize_정상호출시_키워드와요약을반환한다() async throws {
        let sut = makeSUT()
        let transcript = Transcript.stub(text: "전사본")
        let summary = Summary.stub(text: "요약본")
        let keywords = [Keyword.stub(word: "키워드")]

        await sut.summaryRepository.setResult(.success((keywords, summary)))
        await sut.summaryRepository.expectSummarize(
            callCount: 1,
            transcriptText: transcript.sections.map(\.text).joined(separator: "\n")
        )

        let result = try await sut.useCase.summarize(transcript: transcript, language: .ko)

        XCTAssertEqual(result.summary.text, "요약본")
        XCTAssertEqual(result.keywords.first?.word, "키워드")
        await sut.summaryRepository.verify()
    }

    func test_summarize_요약실패시_analysisFailed에러를던진다() async {
        let sut = makeSUT()
        let transcript = Transcript.stub(text: "전사본")
        await sut.summaryRepository.setResult(.failure(.summarizeFailed))

        do {
            _ = try await sut.useCase.summarize(transcript: transcript, language: .ko)
            XCTFail("에러가 발생해야 합니다.")
        } catch {
            guard case VoiceNoteUseCaseError.analysisFailed = error else {
                return XCTFail("잘못된 에러 타입: \(error)")
            }
        }
    }
}
