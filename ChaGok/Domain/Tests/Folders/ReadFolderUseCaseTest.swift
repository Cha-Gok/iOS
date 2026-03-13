import XCTest
@testable import Domain

final class ReadFolderUseCaseTest: XCTestCase {
    typealias UseCaseError = ReadFolderUseCaseError
}

// MARK: - Success Cases

extension ReadFolderUseCaseTest {
    /// 성공 Case: 모든 폴더 목록을 정상적으로 반환할 때
    func test_execute_returnsFolders_whenRepositorySucceeds() async throws {
        // Given
        let expectedFolders = [
            Folder(path: URL(fileURLWithPath: "/1"), name: "Folder 1"),
            Folder(path: URL(fileURLWithPath: "/2"), name: "Folder 2")
        ]
        let repository = MockFolderRepository(fetchAllBehavior: .success(expectedFolders))
        let useCase = DefaultReadFolderUseCase(repository: repository)

        // When
        let folders = try await useCase.execute()

        // Then
        XCTAssertEqual(folders.count, 2)
        XCTAssertEqual(folders[0].name, "Folder 1")
        XCTAssertEqual(folders[0].id, expectedFolders[0].id)
        XCTAssertEqual(folders[1].name, "Folder 2")
        XCTAssertEqual(folders[1].id, expectedFolders[1].id)
        let callCount = await repository.fetchAllCallCount
        XCTAssertEqual(callCount, 1, "Repository의 fetchAll이 1번 호출되어야 합니다.")
    }
}

// MARK: - Error Cases

extension ReadFolderUseCaseTest {

    /// 조회 실패 Case: fetchFailed 에러 전파 확인
    func test_execute_throwsFetchFailed_whenRepositoryReturnsFetchFailed() async {
        // Given
        let repository = MockFolderRepository(fetchAllBehavior: .fetchFailed)
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

        let callCount = await repository.fetchAllCallCount
        XCTAssertEqual(callCount, 1, "Repository의 fetchAll이 1번 호출되어야 합니다.")
    }

    /// 찾을 수 없는 경우 Case: Repository에서 .notFound를 반환할 때 동일하게 전파되는지 확인
    func test_execute_throwsNotFound_whenRepositoryReturnsNotFound() async {
        // Given
        let repository = MockFolderRepository(fetchAllBehavior: .notFound)
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

        let callCount = await repository.fetchAllCallCount
        XCTAssertEqual(callCount, 1, "Repository의 fetchAll이 1번 호출되어야 합니다.")
    }

    /// 매핑 확인 Case: Repository에서 .createFailed를 반환할 때 .unknown으로 맵핑되는지 확인
    func test_execute_throwsUnknown_whenRepositoryReturnsCreateFailed() async {
        // Given
        let repository = MockFolderRepository(fetchAllBehavior: .createFailed)
        let useCase = DefaultReadFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("생성 실패 시 .unknown으로 래핑되어야 합니다.")
        } catch UseCaseError.unknown(let error) {
            guard let repoError = error as? FolderRepositoryError else {
                return XCTFail("Unknown 에러 내부는 FolderRepositoryError가 적용되어야 합니다. ( Typed Throws )")
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

        let callCount = await repository.fetchAllCallCount
        XCTAssertEqual(callCount, 1, "Repository의 fetchAll이 1번 호출되어야 합니다.")
    }

    /// 매핑 확인 Case: Repository에서 .updateFailed를 반환할 때 .unknown으로 맵핑되는지 확인
    func test_execute_throwsUnknown_whenRepositoryReturnsUpdateFailed() async {
        // Given
        let repository = MockFolderRepository(fetchAllBehavior: .updateFailed)
        let useCase = DefaultReadFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("수정 실패 시 .unknown으로 래핑되어야 합니다.")
        } catch UseCaseError.unknown(let error) {
            guard let repoError = error as? FolderRepositoryError else {
                return XCTFail("Unknown 에러 내부는 FolderRepositoryError가 적용되어야 합니다. ( Typed Throws )")
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

        let callCount = await repository.fetchAllCallCount
        XCTAssertEqual(callCount, 1, "Repository의 fetchAll이 1번 호출되어야 합니다.")
    }

    /// 알 수 없는 에러 Case: Repository에서 맵핑되지 않은 에러를 던질 때 .unknown으로 래핑되는지 확인
    func test_execute_throwsUnknown_whenRepositoryThrowsUnknown() async {
        // Given
        struct Dummy: Error {}
        let dummyError = Dummy()
        let repository = MockFolderRepository(fetchAllBehavior: .unknown(dummyError))
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

        let callCount = await repository.fetchAllCallCount
        XCTAssertEqual(callCount, 1, "Repository의 fetchAll이 1번 호출되어야 합니다.")
    }
}

// MARK: - Error Cases ( Cancelled )

extension ReadFolderUseCaseTest {

    /// 작업 취소 Case: repository Cancelled의 경우 UseCase.Cancelled와 대칭 확인
    func test_execute_throwsCancelled_whenRepositoryReturnsCancelled() async {
        // Given
        let repository = MockFolderRepository(fetchAllBehavior: .cancelled)
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

        let callCount = await repository.fetchAllCallCount
        XCTAssertEqual(callCount, 1, "Repository의 fetchAll이 1번 호출되어야 합니다.")
    }

    /// 취소 Case: 작업이 즉시 취소된 경우 execute 함수 내부 isCancelled를 검증한다
    func test_execute_throwsCancelled_whenTaskIsCancelledPreemptively() async {
        // Given
        let useCase = DefaultReadFolderUseCase(
            repository: MockFolderRepository(
                fetchAllBehavior: .success([])
            )
        )

        // When & Then
        let task = Task { try await useCase.execute() }
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("작업이 즉시 취소되었으므로 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }

}
