@testable import Domain
import XCTest

final class UpdateVoiceNoteUseCaseTest: XCTestCase {
    typealias UseCaseError = UpdateVoiceNoteUseCaseError
}

// MARK: - 성공 케이스

extension UpdateVoiceNoteUseCaseTest {
    func test_정상상태_음성메모업데이트시_업데이트된객체를반환한다() async throws {
        // Given
        let expectedVoiceNote = VoiceNote.stub()
        let repository = MockVoiceNoteUpdateRepository()

        await repository.setResult(.success(expectedVoiceNote))
        await repository.expectUpdate(callCount: 1, voiceNote: expectedVoiceNote)

        let useCase = DefaultUpdateVoiceNoteUseCase(repository: repository)

        // When
        let result = try await useCase.execute(expectedVoiceNote)

        // Then
        XCTAssertEqual(result.id, expectedVoiceNote.id)
        XCTAssertEqual(result.title, expectedVoiceNote.title)
        await repository.verify()
    }
}

// MARK: - 에러 케이스

extension UpdateVoiceNoteUseCaseTest {
    func test_리포지토리업데이트실패상태_음성메모업데이트시_updateFailed에러를던진다() async {
        // Given
        let voiceNote = VoiceNote.stub()
        let repository = MockVoiceNoteUpdateRepository()

        await repository.setResult(.failure(.updateFailed))
        await repository.expectUpdate(callCount: 1)

        let useCase = DefaultUpdateVoiceNoteUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(voiceNote)
            XCTFail("업데이트 실패 시 .updateFailed 에러가 발생해야 합니다.")
        } catch UseCaseError.updateFailed {
            // Success
            await repository.verify()
        } catch {
            XCTFail("Expected .updateFailed, got \(error)")
        }
    }

    func test_알수없는에러발생상태_음성메모업데이트시_unknown에러를던진다() async {
        // Given
        let voiceNote = VoiceNote.stub()
        struct Dummy: Error {}
        let dummyError = Dummy()
        let repository = MockVoiceNoteUpdateRepository()

        await repository.setResult(.failure(.unknown(dummyError)))
        await repository.expectUpdate(callCount: 1)

        let useCase = DefaultUpdateVoiceNoteUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(voiceNote)
            XCTFail("알 수 없는 에러 시 .unknown으로 래핑되어야 합니다.")
        } catch UseCaseError.unknown(let error) {
            XCTAssertTrue(error is VoiceNoteUpdateRepositoryError)
            await repository.verify()
        } catch {
            XCTFail("Expected .unknown, got \(error)")
        }
    }
}

// MARK: - 취소 케이스

extension UpdateVoiceNoteUseCaseTest {
    func test_작업취소상태_음성메모업데이트시_cancelled에러를던진다() async {
        // Given
        let voiceNote = VoiceNote.stub()
        let repository = MockVoiceNoteUpdateRepository()

        await repository.setResult(.failure(.cancelled))
        await repository.expectUpdate(callCount: 1)

        let useCase = DefaultUpdateVoiceNoteUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(voiceNote)
            XCTFail("작업 취소 시 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
            await repository.verify()
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }
}
