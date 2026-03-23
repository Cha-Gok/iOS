@testable import Domain
import Core
import XCTest

final class UpdateVoiceNoteUseCaseTest: XCTestCase {}

// MARK: - 성공 케이스

extension UpdateVoiceNoteUseCaseTest {
    func test_정상상태_음성메모업데이트시_업데이트된객체를반환한다() async throws {
        let repository = MockVoiceNoteUpdateRepository()
        let sut = DefaultUpdateVoiceNoteUseCase(repository: repository)

        // Given
        let expectedVoiceNote = VoiceNote.stub()

        await repository.setResult(.success(expectedVoiceNote))
        await repository.expectUpdate(callCount: 1, voiceNote: expectedVoiceNote)

        // When
        let result = try await sut.execute(expectedVoiceNote)

        // Then
        XCTAssertEqual(result.id, expectedVoiceNote.id)
        XCTAssertEqual(result.title, expectedVoiceNote.title)
        await repository.verify()
    }
}

// MARK: - 에러 케이스

extension UpdateVoiceNoteUseCaseTest {
    func test_리포지토리업데이트실패상태_음성메모업데이트시_updateFailed에러를던진다() async {
        let repository = MockVoiceNoteUpdateRepository()
        let sut = DefaultUpdateVoiceNoteUseCase(repository: repository)

        // Given
        let voiceNote = VoiceNote.stub()

        await repository.setResult(.failure(.updateFailed))
        await repository.expectUpdate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute(voiceNote)
            XCTFail("UpdateVoiceNoteUseCaseError.updateFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .updateFailed = error else {
                return XCTFail("예상한 에러는 UpdateVoiceNoteUseCaseError.updateFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await repository.verify()
    }

    func test_알수없는에러발생상태_음성메모업데이트시_unknown에러를던진다() async {
        let repository = MockVoiceNoteUpdateRepository()
        let sut = DefaultUpdateVoiceNoteUseCase(repository: repository)

        // Given
        let voiceNote = VoiceNote.stub()
        struct DummyError: Error {}
        let expectedError = DummyError()

        await repository.setResult(.failure(.unknown(expectedError)))
        await repository.expectUpdate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute(voiceNote)
            XCTFail("UpdateVoiceNoteUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let underlyingError) = error else {
                return XCTFail("예상한 에러는 UpdateVoiceNoteUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
            XCTAssertTrue(underlyingError is DummyError)
        }
        await repository.verify()
    }
}

// MARK: - 취소 케이스

extension UpdateVoiceNoteUseCaseTest {
    func test_작업취소상태_음성메모업데이트시_cancelled에러를던진다() async {
        let repository = MockVoiceNoteUpdateRepository()
        let sut = DefaultUpdateVoiceNoteUseCase(repository: repository)

        // Given
        let voiceNote = VoiceNote.stub()

        await repository.setResult(.failure(.cancelled))
        await repository.expectUpdate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute(voiceNote)
            XCTFail("UpdateVoiceNoteUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error else {
                return XCTFail("예상한 에러는 UpdateVoiceNoteUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await repository.verify()
    }
}
