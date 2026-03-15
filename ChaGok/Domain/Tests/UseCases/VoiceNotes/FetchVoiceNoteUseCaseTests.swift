import XCTest

@testable import Domain

final class FetchVoiceNoteUseCaseTests: XCTestCase {

    private var repository: MockVoiceNoteFetchRepository!
    private var sut: DefaultFetchVoiceNoteUseCase!

    override func setUp() {
        super.setUp()
        repository = MockVoiceNoteFetchRepository()
        sut = DefaultFetchVoiceNoteUseCase(repository: repository)
    }

    override func tearDown() {
        sut = nil
        repository = nil
        super.tearDown()
    }
}

// MARK: - 성공

extension FetchVoiceNoteUseCaseTests {

    func test_execute_전체조회에성공하면_보이스노트목록을반환한다() async throws {
        // Given
        let folderID = UUID()
        let expectedNotes = [
            VoiceNote.stub(title: "Title 1"),
            VoiceNote.stub(title: "Title 2"),
        ]
        await repository.setFetchAllResult(.success(expectedNotes))
        await repository.expectFetchAll(callCount: 1, folderID: folderID)

        // When
        let result = try await sut.execute(folderID: folderID)

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first?.title, "Title 1")
        XCTAssertEqual(result.last?.title, "Title 2")
        await repository.verify()
    }

    func test_executeById_ID조회에성공하면_보이스노트를반환한다() async throws {
        // Given
        let id = UUID()
        let expectedNote = VoiceNote.stub(id: id, title: "Title")
        await repository.setFetchByIdResult(.success(expectedNote))
        await repository.expectFetchById(callCount: 1, id: id)

        // When
        let result = try await sut.execute(byId: id)

        // Then
        XCTAssertEqual(result.id, id)
        XCTAssertEqual(result.title, "Title")
        await repository.verify()
    }
}

// MARK: - 실패 / 에러 매핑

extension FetchVoiceNoteUseCaseTests {

    func test_execute_전체조회가실패하면_fetchAllFailed에러를던진다() async {
        // Given
        let folderID = UUID()
        await repository.setFetchAllResult(.failure(.fetchAllFailed(folderID: folderID)))
        await repository.expectFetchAll(callCount: 1, folderID: folderID)

        // When
        do {
            _ = try await sut.execute(folderID: folderID)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .fetchAllFailed(let mappedFolderID) = error else {
                return XCTFail("expected .fetchAllFailed, got \(error)")
            }
            XCTAssertEqual(mappedFolderID, folderID)
        }

        await repository.verify()
    }

    func test_executeById_레코드를찾을수없으면_recordNotFound에러를던진다() async {
        // Given
        let id = UUID()
        await repository.setFetchByIdResult(.failure(.recordNotFound(id: id)))
        await repository.expectFetchById(callCount: 1, id: id)

        // When
        do {
            _ = try await sut.execute(byId: id)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .recordNotFound(let mappedID) = error else {
                return XCTFail("expected .recordNotFound, got \(error)")
            }
            XCTAssertEqual(mappedID, id)
        }

        await repository.verify()
    }

    func test_execute_리포지토리가조회실패를반환하면_fetchFailed에러를던진다() async {
        // Given
        let folderID = UUID()
        let targetID = UUID()
        await repository.setFetchAllResult(.failure(.fetchFailed(id: targetID)))
        await repository.expectFetchAll(callCount: 1, folderID: folderID)

        // When
        do {
            _ = try await sut.execute(folderID: folderID)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .fetchFailed(let mappedID) = error else {
                return XCTFail("expected .fetchFailed, got \(error)")
            }
            XCTAssertEqual(mappedID, targetID)
        }

        await repository.verify()
    }

    func test_execute_리포지토리가취소를반환하면_cancelled에러를던진다() async {
        // Given
        let folderID = UUID()
        await repository.setFetchAllResult(.failure(.cancelled))
        await repository.expectFetchAll(callCount: 1, folderID: folderID)

        // When
        do {
            _ = try await sut.execute(folderID: folderID)
            XCTFail("에러를 throw 해야 합니다.")
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
        let folderID = UUID()
        struct DummyError: Error {}
        await repository.setFetchAllResult(.failure(.unknown(DummyError())))
        await repository.expectFetchAll(callCount: 1, folderID: folderID)

        // When
        do {
            _ = try await sut.execute(folderID: folderID)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .unknown(let underlying) = error else {
                return XCTFail("expected .unknown, got \(error)")
            }
            XCTAssertTrue(underlying is DummyError)
        }

        await repository.verify()
    }

    func test_executeById_리포지토리가전체조회실패를반환하면_fetchAllFailed에러를던진다() async {
        // Given
        let id = UUID()
        let folderID = UUID()
        await repository.setFetchByIdResult(.failure(.fetchAllFailed(folderID: folderID)))
        await repository.expectFetchById(callCount: 1, id: id)

        // When
        do {
            _ = try await sut.execute(byId: id)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .fetchAllFailed(let mappedFolderID) = error else {
                return XCTFail("expected .fetchAllFailed, got \(error)")
            }
            XCTAssertEqual(mappedFolderID, folderID)
        }

        await repository.verify()
    }

    func test_executeById_리포지토리가조회실패를반환하면_fetchFailed에러를던진다() async {
        // Given
        let id = UUID()
        await repository.setFetchByIdResult(.failure(.fetchFailed(id: id)))
        await repository.expectFetchById(callCount: 1, id: id)

        // When
        do {
            _ = try await sut.execute(byId: id)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .fetchFailed(let mappedID) = error else {
                return XCTFail("expected .fetchFailed, got \(error)")
            }
            XCTAssertEqual(mappedID, id)
        }

        await repository.verify()
    }

    func test_executeById_리포지토리가취소를반환하면_cancelled에러를던진다() async {
        // Given
        let id = UUID()
        await repository.setFetchByIdResult(.failure(.cancelled))
        await repository.expectFetchById(callCount: 1, id: id)

        // When
        do {
            _ = try await sut.execute(byId: id)
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .cancelled = error else {
                return XCTFail("expected .cancelled, got \(error)")
            }
        }

        await repository.verify()
    }

    func test_executeById_리포지토리가알수없는에러를반환하면_unknown에러를던진다() async {
        // Given
        struct DummyError: Error {}

        let id = UUID()
        await repository.setFetchByIdResult(.failure(.unknown(DummyError())))
        await repository.expectFetchById(callCount: 1, id: id)

        // When
        do {
            _ = try await sut.execute(byId: id)
            XCTFail("에러를 throw 해야 합니다.")
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

extension FetchVoiceNoteUseCaseTests {

    func test_execute_태스크가취소되면_리포지토리호출없이cancelled에러를던진다() async {
        guard let sut else {
            return XCTFail("sut should be initialized in setUp")
        }

        // Given
        let folderID = UUID()
        await repository.setFetchAllResult(.success([]))
        await repository.expectFetchAll(callCount: 0)

        // When
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.execute(folderID: folderID)
        }

        // Then
        do {
            _ = try await task.value
            XCTFail("취소 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? FetchVoiceNoteUseCaseError else {
                return XCTFail("expected .cancelled, got \(error)")
            }
        }

        await repository.verify()
    }

    func test_executeById_태스크가취소되면_리포지토리호출없이cancelled에러를던진다() async {
        guard let sut else {
            return XCTFail("sut should be initialized in setUp")
        }

        // Given
        let id = UUID()
        await repository.setFetchByIdResult(.success(VoiceNote.stub(id: id)))
        await repository.expectFetchById(callCount: 0)

        // When
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.execute(byId: id)
        }

        // Then
        do {
            _ = try await task.value
            XCTFail("취소 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? FetchVoiceNoteUseCaseError else {
                return XCTFail("expected .cancelled, got \(error)")
            }
        }

        await repository.verify()
    }
}
