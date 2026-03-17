@testable import Domain
import XCTest

final class CreateVoiceNoteUseCaseTest: XCTestCase {
    typealias UseCaseError = CreateVoiceNoteUseCaseError
}

// MARK: - 성공 케이스

extension CreateVoiceNoteUseCaseTest {
    func test_정상상태_음성메모생성시_생성된객체를반환한다() async throws {
        // Given
        let voiceRecord = VoiceRecord.stub()
        let expectedVoiceNote = VoiceNote.stub(voiceRecord: voiceRecord)
        let repository = MockVoiceNoteCreateRepository()

        await repository.setResult(.success(expectedVoiceNote))
        await repository.expectCreate(callCount: 1, voiceRecordID: voiceRecord.id)

        let useCase = DefaultCreateVoiceNoteUseCase(repository: repository)

        // When
        let result = try await useCase.execute(voiceRecord)

        // Then
        XCTAssertEqual(result.id, expectedVoiceNote.id)
        XCTAssertEqual(result.voiceRecord.id, voiceRecord.id)
        await repository.verify()
    }
}

// MARK: - 에러 케이스

extension CreateVoiceNoteUseCaseTest {
    func test_리포지토리생성실패상태_음성메모생성시_createFailed에러를던진다() async {
        // Given
        let voiceRecord = VoiceRecord.stub()
        let repository = MockVoiceNoteCreateRepository()

        await repository.setResult(.failure(.createFailed))
        await repository.expectCreate(callCount: 1)

        let useCase = DefaultCreateVoiceNoteUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(voiceRecord)
            XCTFail("생성 실패 시 .createFailed 에러가 발생해야 합니다.")
        } catch UseCaseError.createFailed {
            // Success
            await repository.verify()
        } catch {
            XCTFail("Expected .createFailed, got \(error)")
        }
    }

    func test_알수없는에러발생상태_음성메모생성시_unknown에러를던진다() async {
        // Given
        let voiceRecord = VoiceRecord.stub()
        struct Dummy: Error {}
        let dummyError = Dummy()
        let repository = MockVoiceNoteCreateRepository()

        await repository.setResult(.failure(.unknown(dummyError)))
        await repository.expectCreate(callCount: 1)

        let useCase = DefaultCreateVoiceNoteUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(voiceRecord)
            XCTFail("알 수 없는 에러 시 .unknown으로 래핑되어야 합니다.")
        } catch UseCaseError.unknown(let error) {
            XCTAssertTrue(error is VoiceNoteCreateRepositoryError)
            await repository.verify()
        } catch {
            XCTFail("Expected .unknown, got \(error)")
        }
    }

    func test_작업취소상태_음성메모생성시_cancelled에러를던진다() async {
        // Given
        let voiceRecord = VoiceRecord.stub()
        let repository = MockVoiceNoteCreateRepository()

        await repository.setResult(.failure(.cancelled))
        await repository.expectCreate(callCount: 1)

        let useCase = DefaultCreateVoiceNoteUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(voiceRecord)
            XCTFail("작업 취소 시 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
            await repository.verify()
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }
}
