@testable import Domain
import XCTest

final class FetchVoiceNoteUseCaseTest: XCTestCase {
    typealias UseCaseError = FetchVoiceNoteUseCaseError
}

// MARK: - 성공 케이스

extension FetchVoiceNoteUseCaseTest {
    func test_정상상태_특정폴더내음성메모조회시_리포지토리에서가져온목록을반환한다() async throws {
        // Given
        let folderID = UUID()
        let expectedVoiceNotes = [VoiceNote.stub(folderID: folderID)]
        let repository = MockVoiceNoteFetchRepository()

        await repository.setFetchAllResult(.success(expectedVoiceNotes))
        await repository.expectFetchAll(callCount: 1, folderID: folderID)

        let useCase = DefaultFetchVoiceNoteUseCase(repository: repository)

        // When
        let result = try await useCase.execute(folderID: folderID)

        // Then
        XCTAssertEqual(result.count, expectedVoiceNotes.count)
        XCTAssertEqual(result[0].folderID, folderID)
        await repository.verify()
    }

    func test_정상상태_특정ID로음성메모조회시_리포지토리에서가져온객체를반환한다() async throws {
        // Given
        let voiceNoteID = UUID()
        let expectedVoiceNote = VoiceNote.stub(id: voiceNoteID)
        let repository = MockVoiceNoteFetchRepository()

        await repository.setFetchByIdResult(.success(expectedVoiceNote))
        await repository.expectFetchById(callCount: 1, id: voiceNoteID)

        let useCase = DefaultFetchVoiceNoteUseCase(repository: repository)

        // When
        let result = try await useCase.execute(byId: voiceNoteID)

        // Then
        XCTAssertEqual(result.id, voiceNoteID)
        await repository.verify()
    }
}

// MARK: - 에러 케이스

extension FetchVoiceNoteUseCaseTest {
    func test_리포지토리조회실패상태_음성메모조회시_fetchAllFailed에러를던진다() async {
        // Given
        let folderID = UUID()
        let repository = MockVoiceNoteFetchRepository()

        await repository.setFetchAllResult(.failure(.fetchAllFailed(folderID: folderID)))
        await repository.expectFetchAll(callCount: 1, folderID: folderID)

        let useCase = DefaultFetchVoiceNoteUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(folderID: folderID)
            XCTFail("조회 실패 시 .fetchAllFailed 에러가 발생해야 합니다.")
        } catch UseCaseError.fetchAllFailed(let failedID) {
            XCTAssertEqual(failedID, folderID)
            await repository.verify()
        } catch {
            XCTFail("Expected .fetchAllFailed, got \(error)")
        }
    }

    func test_알수없는에러발생상태_음성메모조회시_unknown에러를던진다() async {
        // Given
        let folderID = UUID()
        struct Dummy: Error {}
        let dummyError = Dummy()
        let repository = MockVoiceNoteFetchRepository()

        await repository.setFetchAllResult(.failure(.unknown(dummyError)))
        await repository.expectFetchAll(callCount: 1, folderID: folderID)

        let useCase = DefaultFetchVoiceNoteUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(folderID: folderID)
            XCTFail("알 수 없는 에러 시 .unknown으로 래핑되어야 합니다.")
        } catch UseCaseError.unknown(let error) {
            XCTAssertTrue(error is Dummy)
            await repository.verify()
        } catch {
            XCTFail("Expected .unknown, got \(error)")
        }
    }

    func test_작업취소상태_음성메모조회시_cancelled에러를던진다() async {
        // Given
        let folderID = UUID()
        let repository = MockVoiceNoteFetchRepository()

        await repository.setFetchAllResult(.failure(.cancelled))
        await repository.expectFetchAll(callCount: 1, folderID: folderID)

        let useCase = DefaultFetchVoiceNoteUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(folderID: folderID)
            XCTFail("작업 취소 시 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
            await repository.verify()
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }
}
