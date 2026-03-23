@testable import Domain
import Core
import XCTest

final class FetchVoiceNoteUseCaseTest: XCTestCase {}

// MARK: - 성공 케이스

extension FetchVoiceNoteUseCaseTest {
    func test_정상상태_특정폴더내음성메모조회시_리포지토리에서가져온목록을반환한다() async throws {
        let repository = MockVoiceNoteFetchRepository()
        let sut = DefaultFetchVoiceNoteUseCase(repository: repository)

        // Given
        let folderID = UUID()
        let expectedVoiceNotes = [VoiceNote.stub(folderID: folderID)]

        await repository.setFetchAllResult(.success(expectedVoiceNotes))
        await repository.expectFetchAll(callCount: 1, folderID: folderID)

        // When
        let result = try await sut.execute(folderID: folderID)

        // Then
        XCTAssertEqual(result.count, expectedVoiceNotes.count)
        XCTAssertEqual(result[0].folderID, folderID)
        await repository.verify()
    }

    func test_정상상태_특정ID로음성메모조회시_리포지토리에서가져온객체를반환한다() async throws {
        let repository = MockVoiceNoteFetchRepository()
        let sut = DefaultFetchVoiceNoteUseCase(repository: repository)

        // Given
        let voiceNoteID = UUID()
        let expectedVoiceNote = VoiceNote.stub(id: voiceNoteID)

        await repository.setFetchByIdResult(.success(expectedVoiceNote))
        await repository.expectFetchById(callCount: 1, id: voiceNoteID)

        // When
        let result = try await sut.execute(byId: voiceNoteID)

        // Then
        XCTAssertEqual(result.id, voiceNoteID)
        await repository.verify()
    }
}

// MARK: - 에러 케이스

extension FetchVoiceNoteUseCaseTest {
    func test_리포지토리조회실패상태_음성메모조회시_fetchAllFailed에러를던진다() async {
        let repository = MockVoiceNoteFetchRepository()
        let sut = DefaultFetchVoiceNoteUseCase(repository: repository)

        // Given
        let folderID = UUID()

        await repository.setFetchAllResult(.failure(.fetchAllFailed(folderID: folderID)))
        await repository.expectFetchAll(callCount: 1, folderID: folderID)

        // When & Then
        do {
            _ = try await sut.execute(folderID: folderID)
            XCTFail("FetchVoiceNoteUseCaseError.fetchAllFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .fetchAllFailed(let failedID) = error else {
                return XCTFail("예상한 에러는 FetchVoiceNoteUseCaseError.fetchAllFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
            XCTAssertEqual(failedID, folderID)
        }
        await repository.verify()
    }

    func test_알수없는에러발생상태_음성메모조회시_unknown에러를던진다() async {
        let repository = MockVoiceNoteFetchRepository()
        let sut = DefaultFetchVoiceNoteUseCase(repository: repository)

        // Given
        let folderID = UUID()
        struct DummyError: Error {}
        let expectedError = DummyError()

        await repository.setFetchAllResult(.failure(.unknown(expectedError)))
        await repository.expectFetchAll(callCount: 1, folderID: folderID)

        // When & Then
        do {
            _ = try await sut.execute(folderID: folderID)
            XCTFail("FetchVoiceNoteUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let underlyingError) = error else {
                return XCTFail("예상한 에러는 FetchVoiceNoteUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
            XCTAssertTrue(underlyingError is DummyError)
        }
        await repository.verify()
    }

    func test_작업취소상태_음성메모조회시_cancelled에러를던진다() async {
        let repository = MockVoiceNoteFetchRepository()
        let sut = DefaultFetchVoiceNoteUseCase(repository: repository)

        // Given
        let folderID = UUID()

        await repository.setFetchAllResult(.failure(.cancelled))
        await repository.expectFetchAll(callCount: 1, folderID: folderID)

        // When & Then
        do {
            _ = try await sut.execute(folderID: folderID)
            XCTFail("FetchVoiceNoteUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error else {
                return XCTFail("예상한 에러는 FetchVoiceNoteUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await repository.verify()
    }
}
