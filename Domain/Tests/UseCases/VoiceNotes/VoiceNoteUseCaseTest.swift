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

// MARK: - Summarize

extension VoiceNoteUseCaseTest {
    func test_summarize_정상호출시_STT및요약을순차적으로수행한다() async throws {
        let sut = makeSUT()
        let audioPath = "test.m4a"
        let transcript = Transcript.stub(text: "전사본")
        let summary = Summary.stub(text: "요약본")
        let keywords = [Keyword.stub(word: "키워드")]

        await sut.sttRepository.setResult(.success(transcript))
        await sut.sttRepository.expectTranscribe(callCount: 1, audioFilePath: audioPath)

        await sut.summaryRepository.setResult(.success((keywords, summary)))
        await sut.summaryRepository.expectSummarize(callCount: 1, transcriptText: transcript.text)

        let result = try await sut.useCase.summarize(audioFilePath: audioPath, language: .ko)

        XCTAssertEqual(result.transcript.text, "전사본")
        XCTAssertEqual(result.summary.text, "요약본")
        XCTAssertEqual(result.keywords.first?.word, "키워드")
        await sut.sttRepository.verify()
        await sut.summaryRepository.verify()
    }

    func test_summarize_STT실패시_analysisFailed에러를던진다() async {
        let sut = makeSUT()
        await sut.sttRepository.setResult(.failure(.transcribeFailed))

        do {
            _ = try await sut.useCase.summarize(audioFilePath: "test.m4a", language: .ko)
            XCTFail("에러가 발생해야 합니다.")
        } catch {
            guard case VoiceNoteUseCaseError.analysisFailed = error else {
                return XCTFail("잘못된 에러 타입: \(error)")
            }
        }
    }
}
