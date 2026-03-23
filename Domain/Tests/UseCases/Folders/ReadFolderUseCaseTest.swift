@testable import Domain
import Core
import XCTest

final class ReadFolderUseCaseTest: XCTestCase {}

// MARK: - 성공 케이스

extension ReadFolderUseCaseTest {
    func test_정상상태_폴더조회시_전체폴더목록을반환한다() async throws {
        let repository = MockFolderRepository()
        let sut = DefaultReadFolderUseCase(repository: repository)

        // Given
        let expectedFolders = [
            Folder(name: "Folder 1"),
            Folder(name: "Folder 2")
        ]
        await repository.setFetchAllResult(.success(expectedFolders))
        await repository.expectFetchAll(callCount: 1)

        // When
        let folders = try await sut.execute()

        // Then
        XCTAssertEqual(folders.count, 2)
        XCTAssertEqual(folders[0].name, "Folder 1")
        XCTAssertEqual(folders[0].id, expectedFolders[0].id)
        XCTAssertEqual(folders[1].name, "Folder 2")
        XCTAssertEqual(folders[1].id, expectedFolders[1].id)
        await repository.verify()
    }
}

// MARK: - 에러 케이스

extension ReadFolderUseCaseTest {
    func test_리포지토리조회실패상태_폴더조회시_fetchFailed에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultReadFolderUseCase(repository: repository)

        // Given
        await repository.setFetchAllResult(.failure(.fetchFailed))
        await repository.expectFetchAll(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("ReadFolderUseCaseError.fetchFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .fetchFailed = error else {
                return XCTFail(
                    "예상한 에러는 ReadFolderUseCaseError.fetchFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_폴더미존재상태_폴더조회시_notFound에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultReadFolderUseCase(repository: repository)

        // Given
        await repository.setFetchAllResult(.failure(.notFound))
        await repository.expectFetchAll(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("ReadFolderUseCaseError.notFound 에러를 throw 해야 합니다.")
        } catch {
            guard case .notFound = error else {
                return XCTFail(
                    "예상한 에러는 ReadFolderUseCaseError.notFound 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_리포지토리알수없는에러상태_폴더조회시_unknown에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultReadFolderUseCase(repository: repository)

        // Given
        struct DummyError: Error {}
        let expectedError = DummyError()
        await repository.setFetchAllResult(.failure(.unknown(expectedError)))
        await repository.expectFetchAll(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("ReadFolderUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let wrappedError) = error else {
                return XCTFail(
                    "예상한 에러는 ReadFolderUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }

            guard let repoError = wrappedError as? FolderRepositoryError,
                  case .unknown(let underlyingError) = repoError
            else {
                return XCTFail("Unknown 에러 내부에는 FolderRepositoryError.unknown이 포함되어야 합니다.")
            }
            XCTAssertTrue(underlyingError is DummyError)
        }

        await repository.verify()
    }
}

// MARK: - 취소 케이스

extension ReadFolderUseCaseTest {
    func test_작업취소상태_폴더조회시_cancelled에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultReadFolderUseCase(repository: repository)

        // Given
        await repository.setFetchAllResult(.failure(.cancelled))
        await repository.expectFetchAll(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("ReadFolderUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error else {
                return XCTFail(
                    "예상한 에러는 ReadFolderUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_태스크이미취소상태_폴더조회시_즉시cancelled에러를던진다() async throws {
        let repository = MockFolderRepository()
        let sut = DefaultReadFolderUseCase(repository: repository)

        // Given
        await repository.setFetchAllResult(.success([]))
        await repository.expectFetchAll(callCount: 0)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await sut.execute()
        }

        do {
            _ = try await task.value
            XCTFail("ReadFolderUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? ReadFolderUseCaseError else {
                return XCTFail(
                    "예상한 에러는 ReadFolderUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }
}
