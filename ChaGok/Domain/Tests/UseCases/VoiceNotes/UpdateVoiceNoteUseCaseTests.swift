import Foundation
import XCTest

@testable import Domain

final class UpdateVoiceNoteUseCaseTests: XCTestCase {

    private var repository: MockVoiceNoteUpdateRepository!
    private var sut: DefaultUpdateVoiceNoteUseCase!

    override func setUp() {
        super.setUp()
        repository = MockVoiceNoteUpdateRepository()
        sut = DefaultUpdateVoiceNoteUseCase(repository: repository)
    }

    override func tearDown() {
        sut = nil
        repository = nil
        super.tearDown()
    }
}

// MARK: - 성공

extension UpdateVoiceNoteUseCaseTests {

    func test_execute_유효한입력을넣으면_업데이트된보이스노트를반환한다() async throws {
        // Given
        let original = VoiceNote.stub(title: "Original")
        let updated = VoiceNote.stub(id: original.id, title: "Updated")
        await repository.setResult(.success(updated))
        await repository.expectUpdate(callCount: 1, voiceNote: updated)

        // When
        let result = try await sut.execute(updated)

        // Then
        XCTAssertEqual(result.id, updated.id)
        XCTAssertEqual(result.title, "Updated")
        await repository.verify()
    }
}

// MARK: - 실패

extension UpdateVoiceNoteUseCaseTests {

    func test_execute_제목이비어있으면_invalidTitle에러를던진다() async {
        // Given
        let voiceNote = VoiceNote.stub(title: "")
        await repository.expectUpdate(callCount: 0)

        // When
        do {
            _ = try await sut.execute(voiceNote)
            XCTFail("sut.execute()가 에러를 throw해야 하지만, 성공했습니다.")
        } catch {
            // Then
            guard case .invalidTitle = error else {
                return XCTFail("expected .invalidTitle, got \(error)")
            }
        }

        await repository.verify()
    }

    func test_execute_제목이공백이면_invalidTitle에러를던진다() async {
        // Given
        let voiceNote = VoiceNote.stub(title: "   ")
        await repository.expectUpdate(callCount: 0)

        // When
        do {
            _ = try await sut.execute(voiceNote)
            XCTFail("sut.execute()가 에러를 throw해야 하지만, 성공했습니다.")
        } catch {
            // Then
            guard case .invalidTitle = error else {
                return XCTFail("expected .invalidTitle, got \(error)")
            }
        }

        await repository.verify()
    }

    func test_execute_제목이50자를초과하면_invalidLengthTitle에러를던진다() async {
        // Given
        let longTitle = String(repeating: "a", count: 51)
        let voiceNote = VoiceNote.stub(title: longTitle)
        await repository.expectUpdate(callCount: 0)

        // When
        do {
            _ = try await sut.execute(voiceNote)
            XCTFail("sut.execute()가 에러를 throw해야 하지만, 성공했습니다.")
        } catch {
            // Then
            guard case .invalidLengthTitle = error else {
                return XCTFail("expected .invalidLengthTitle, got \(error)")
            }
        }

        await repository.verify()
    }

    func test_execute_리포지토리가업데이트실패를반환하면_updateFailed에러를던진다() async {
        // Given
        let voiceNote = VoiceNote.stub()
        await repository.setResult(.failure(.updateFailed))
        await repository.expectUpdate(callCount: 1, voiceNote: voiceNote)

        // When
        do {
            _ = try await sut.execute(voiceNote)
            XCTFail("sut.execute()가 에러를 throw해야 하지만, 성공했습니다.")
        } catch {
            // Then
            guard case .updateFailed = error else {
                return XCTFail("expected .updateFailed, got \(error)")
            }
        }

        await repository.verify()
    }

    func test_execute_리포지토리가취소를반환하면_cancelled에러를던진다() async {
        // Given
        let voiceNote = VoiceNote.stub()
        await repository.setResult(.failure(.cancelled))
        await repository.expectUpdate(callCount: 1, voiceNote: voiceNote)

        // When
        do {
            _ = try await sut.execute(voiceNote)
            XCTFail("sut.execute()가 에러를 throw해야 하지만, 성공했습니다.")
        } catch {
            // Then
            guard case .cancelled = error else {
                return XCTFail("expected .cancelled, got \(error)")
            }
        }

        await repository.verify()
    }

    func test_execute_리포지토리가알수없는에러를반환하면_unknown에러를던진다() async {
        // Given
        struct DummyError: Error {}
        let voiceNote = VoiceNote.stub()
        await repository.setResult(.failure(.unknown(DummyError())))
        await repository.expectUpdate(callCount: 1, voiceNote: voiceNote)

        // When
        do {
            _ = try await sut.execute(voiceNote)
            XCTFail("sut.execute()가 에러를 throw해야 하지만, 성공했습니다.")
        } catch {
            // Then
            guard case .unknown(let underlying) = error else {
                return XCTFail("expected .unknown, got \(error)")
            }
            XCTAssertTrue(underlying is DummyError)
        }

        await repository.verify()
    }
}

// MARK: - Task 취소

extension UpdateVoiceNoteUseCaseTests {

    func test_execute_실행전에태스크가취소되면_리포지토리호출없이cancelled에러를던진다() async {
        guard let sut else {
            return XCTFail("sut가 setup되지 않았습니다.")
        }

        // Given
        let voiceNote = VoiceNote.stub()
        await repository.setResult(.success(voiceNote))
        await repository.expectUpdate(callCount: 0)

        // When
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.execute(voiceNote)
        }

        // Then
        do {
            _ = try await task.value
            XCTFail("sut.execute()가 취소 에러를 throw해야 하지만, 성공하거나 다른 에러를 throw했습니다.")
        } catch {
            guard case .cancelled = error as? UpdateVoiceNoteUseCaseError else {
                return XCTFail("expected .cancelled, got \(error)")
            }
        }

        await repository.verify()
    }
}
