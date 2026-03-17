@testable import Domain
import XCTest

final class ReadFolderUseCaseTest: XCTestCase {
    typealias UseCaseError = ReadFolderUseCaseError
}

// MARK: - 성공 케이스

extension ReadFolderUseCaseTest {
    func test_폴더_조회_성공_폴더목록을반환한다() async throws {
        // Given
        let expectedFolders = [
            Folder(path: URL(fileURLWithPath: "/1"), name: "Folder 1"),
            Folder(path: URL(fileURLWithPath: "/2"), name: "Folder 2")
        ]
        let repository = MockFolderRepository()
        await repository.setFetchAllResult(.success(expectedFolders))
        await repository.expectFetchAll(callCount: 1)

        let useCase = DefaultReadFolderUseCase(repository: repository)

        // When
        let folders = try await useCase.execute()

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
    func test_폴더_조회_리포지토리조회실패시_fetchFailed에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.setFetchAllResult(.failure(.fetchFailed))
        await repository.expectFetchAll(callCount: 1)

        let useCase = DefaultReadFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("조회 실패 시 .fetchFailed 에러가 발생해야 합니다.")
        } catch UseCaseError.fetchFailed {
            // Success
        } catch {
            XCTFail("Expected .fetchFailed, got \(error)")
        }

        await repository.verify()
    }

    func test_폴더_조회_리포지토리찾을수없음시_notFound에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.setFetchAllResult(.failure(.notFound))
        await repository.expectFetchAll(callCount: 1)

        let useCase = DefaultReadFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("찾을 수 없을 시 .notFound 에러가 발생해야 합니다.")
        } catch UseCaseError.notFound {
            // Success
        } catch {
            XCTFail("Expected .notFound, got \(error)")
        }

        await repository.verify()
    }

    func test_폴더_조회_리포지토리생성실패시_unknown에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.setFetchAllResult(.failure(.createFailed))
        await repository.expectFetchAll(callCount: 1)

        let useCase = DefaultReadFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("생성 실패 시 .unknown으로 래핑되어야 합니다.")
        } catch UseCaseError.unknown(let error) {
            guard let repoError = error as? FolderRepositoryError else {
                return XCTFail("Unknown 에러 내부는 FolderRepositoryError가 적용되어야 합니다.")
            }

            switch repoError {
            case .createFailed:
                break // Success
            default:
                XCTFail("Expected .createFailed, but got \(repoError)")
            }
        } catch {
            XCTFail("Expected .unknown, got \(error)")
        }

        await repository.verify()
    }

    func test_폴더_조회_리포지토리수정실패시_unknown에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.setFetchAllResult(.failure(.updateFailed))
        await repository.expectFetchAll(callCount: 1)

        let useCase = DefaultReadFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("수정 실패 시 .unknown으로 래핑되어야 합니다.")
        } catch UseCaseError.unknown(let error) {
            guard let repoError = error as? FolderRepositoryError else {
                return XCTFail("Unknown 에러 내부는 FolderRepositoryError가 적용되어야 합니다.")
            }

            switch repoError {
            case .updateFailed:
                break // Success
            default:
                XCTFail("Expected .updateFailed, but got \(repoError)")
            }
        } catch {
            XCTFail("Expected .unknown, got \(error)")
        }

        await repository.verify()
    }

    func test_폴더_조회_리포지토리알수없는에러시_unknown에러를던진다() async {
        // Given
        struct Dummy: Error {}
        let dummyError = Dummy()
        let repository = MockFolderRepository()
        await repository.setFetchAllResult(.failure(.unknown(dummyError)))
        await repository.expectFetchAll(callCount: 1)

        let useCase = DefaultReadFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("알 수 없는 에러 발생 시 .unknown으로 래핑되어야 합니다.")
        } catch UseCaseError.unknown(let error) {
            guard let repoError = error as? FolderRepositoryError else {
                return XCTFail("Unknown 에러 내부에는 FolderRepositoryError가 포함되어야 합니다.")
            }

            switch repoError {
            case .unknown(let underlyingError):
                XCTAssertTrue(underlyingError is Dummy)
            default:
                XCTFail("Expected .unknown underlying error, but got \(repoError)")
            }
        } catch {
            XCTFail("Expected .unknown, got \(error)")
        }

        await repository.verify()
    }
}

// MARK: - 취소 케이스

extension ReadFolderUseCaseTest {
    func test_폴더_조회_리포지토리취소시_cancelled에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.setFetchAllResult(.failure(.cancelled))
        await repository.expectFetchAll(callCount: 1)

        let useCase = DefaultReadFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("작업 취소의 경우 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }

        await repository.verify()
    }

    func test_폴더_조회_작업전_즉시cancelled에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.setFetchAllResult(.success([]))
        await repository.expectFetchAll(callCount: 0)

        let useCase = DefaultReadFolderUseCase(repository: repository)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await useCase.execute()
        }

        do {
            _ = try await task.value
            XCTFail("작업이 즉시 취소되었으므로 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }

        await repository.verify()
    }
}
