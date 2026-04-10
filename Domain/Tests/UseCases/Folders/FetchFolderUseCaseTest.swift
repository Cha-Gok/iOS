@testable import Domain
import Core
import DomainTesting
import XCTest

final class FetchFolderUseCaseTest: XCTestCase {}

// MARK: - 성공 케이스

extension FetchFolderUseCaseTest {
    func test_정상상태_폴더조회시_기본폴더와_삭제된폴더를제외한_폴더목록만반환한다() async throws {
        let repository = MockFolderRepository()
        let sut = DefaultFetchFolderUseCase(repository: repository)

        // Given
        let expectedFolders = [
            Folder.stub(name: "기본 폴더", isDeletable: false), // 필터링 대상
            Folder.stub(name: "휴지통에 있는 폴더", deletedAt: Date()), // 필터링 대상
            Folder.stub(name: "Folder 1"), // 기본값 isDeletable: true, deletedAt: nil
            Folder.stub(name: "Folder 2")
        ]
        await repository.setFetchAllResult(.success(expectedFolders))
        await repository.expectFetchAll(callCount: 1)

        // When
        let folders = try await sut.fetchAll()

        // Then
        XCTAssertEqual(folders.count, 2)
        XCTAssertEqual(folders[0].name, "Folder 1")
        XCTAssertEqual(folders[0].id, expectedFolders[2].id)
        XCTAssertEqual(folders[1].name, "Folder 2")
        XCTAssertEqual(folders[1].id, expectedFolders[3].id)
        await repository.verify()
    }
}

// MARK: - 에러 케이스

extension FetchFolderUseCaseTest {
    func test_리포지토리조회실패상태_폴더조회시_fetchFailed에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultFetchFolderUseCase(repository: repository)

        // Given
        await repository.setFetchAllResult(.failure(.fetchFailed))
        await repository.expectFetchAll(callCount: 1)

        // When & Then
        do {
            _ = try await sut.fetchAll()
            XCTFail("FetchFolderUseCaseError.fetchFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .fetchFailed = error else {
                return XCTFail(
                    "예상한 에러는 FetchFolderUseCaseError.fetchFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_폴더미존재상태_폴더조회시_notFound에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultFetchFolderUseCase(repository: repository)

        // Given
        await repository.setFetchAllResult(.failure(.notFound))
        await repository.expectFetchAll(callCount: 1)

        // When & Then
        do {
            _ = try await sut.fetchAll()
            XCTFail("FetchFolderUseCaseError.notFound 에러를 throw 해야 합니다.")
        } catch {
            guard case .notFound = error else {
                return XCTFail(
                    "예상한 에러는 FetchFolderUseCaseError.notFound 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_리포지토리알수없는에러상태_폴더조회시_unknown에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultFetchFolderUseCase(repository: repository)

        // Given
        struct DummyError: Error {}
        let expectedError = DummyError()
        await repository.setFetchAllResult(.failure(.unknown(expectedError)))
        await repository.expectFetchAll(callCount: 1)

        // When & Then
        do {
            _ = try await sut.fetchAll()
            XCTFail("FetchFolderUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let wrappedError) = error else {
                return XCTFail(
                    "예상한 에러는 FetchFolderUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다."
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

extension FetchFolderUseCaseTest {
    func test_작업취소상태_폴더조회시_cancelled에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultFetchFolderUseCase(repository: repository)

        // Given
        await repository.setFetchAllResult(.failure(.cancelled))
        await repository.expectFetchAll(callCount: 1)

        // When & Then
        do {
            _ = try await sut.fetchAll()
            XCTFail("FetchFolderUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error else {
                return XCTFail(
                    "예상한 에러는 FetchFolderUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_태스크이미취소상태_폴더조회시_즉시cancelled에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultFetchFolderUseCase(repository: repository)

        // Given
        await repository.setFetchAllResult(.success([]))
        await repository.expectFetchAll(callCount: 0)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await sut.fetchAll()
        }

        do {
            _ = try await task.value
            XCTFail("FetchFolderUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? FetchFolderUseCaseError else {
                return XCTFail(
                    "예상한 에러는 FetchFolderUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }
}
