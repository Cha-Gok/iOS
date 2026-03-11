import XCTest
@testable import Domain

final class FetchBasicFolderUseCaseTest: XCTestCase {
    typealias UseCaseError = FetchBasicFolderUseCaseError
}

// MARK: - Success Cases

extension FetchBasicFolderUseCaseTest {
    /// 성공 Case: Repository가 정상적으로 Folder를 반환할 때
    func test_execute_returnsFolder_whenRepositorySucceeds() async throws {
        // Given
        let expectedFolder = Folder(path: URL(fileURLWithPath: "/test"), name: "Basic Folder")
        let useCase = DefaultFetchBasicFolderUseCase(
            repository: MockWorkSpaceRepository(
                basicFolderBehavior: .success(expectedFolder)
            )
        )

        // When
        let folder = try await useCase.execute()

        // Then
        XCTAssertEqual(folder.id, expectedFolder.id)
        XCTAssertEqual(folder.name, expectedFolder.name)
    }
}

// MARK: - Error Cases

extension FetchBasicFolderUseCaseTest {
    /// 찾을 수 없음 Case: Repo에서 .notFound를 반환할 때 대칭 확인
    func test_execute_throwsNotFound_whenRepositoryReturnsNotFound() async {
        // Given
        let useCase = DefaultFetchBasicFolderUseCase(
            repository: MockWorkSpaceRepository(
                basicFolderBehavior: .notFound
            )
        )

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("기본 폴더가 없는 경우 .notFound 에러가 발생해야 합니다.")
        } catch UseCaseError.notFound {
            // Success
        } catch {
            XCTFail("Expected .notFound, got \(error)")
        }
    }

    /// 생성 실패 Case: Repo에서 .createFailed를 반환할 때 대칭 확인
    func test_execute_throwsCreateFailed_whenRepositoryReturnsCreateFailed() async {
        // Given
        let useCase = DefaultFetchBasicFolderUseCase(
            repository: MockWorkSpaceRepository(
                basicFolderBehavior: .createFailed
            )
        )

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("생성 실패 시 .createFailed 에러가 발생해야 합니다.")
        } catch UseCaseError.createFailed {
            // Success
        } catch {
            XCTFail("Expected .createFailed, got \(error)")
        }
    }

    /// 알 수 없는 에러 Case: Repository에서 맵핑되지 않은 에러를 던질 때 .unknown으로 래핑되는지 확인
    func test_execute_throwsUnknown_whenRepositoryThrowsUnknown() async {
        // Given
        struct Dummy: Error {}
        let dummyError = Dummy()
        let useCase = DefaultFetchBasicFolderUseCase(
            repository: MockWorkSpaceRepository(
                basicFolderBehavior: .unknown(dummyError)
            )
        )

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("알 수 없는 에러 발생 시 .unknown으로 래핑되어야 합니다.")
        } catch UseCaseError.unknown(let error) {
            // RepoError.unknown 내부의 Dummy 에러가 유지되어야 함
            XCTAssertTrue(error is Dummy)
        } catch {
            XCTFail("Expected .unknown, got \(error)")
        }
    }
}

// MARK: - Error Cases ( Cancelled )

extension FetchBasicFolderUseCaseTest {
    /// 작업 취소 Case: repository Cancelled의 경우 UseCase.Cancelled와 대칭 확인
    func test_execute_throwsCancelled_whenRepositoryReturnsCancelled() async {
        // Given
        let useCase = DefaultFetchBasicFolderUseCase(
            repository: MockWorkSpaceRepository(
                basicFolderBehavior: .cancelled
            )
        )

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("작업 취소의 경우 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }

    /// 취소 Case: 작업이 즉시 취소된 경우
    func test_execute_throwsCancelled_whenTaskIsCancelledPreemptively() async {
        // Given
        let useCase = DefaultFetchBasicFolderUseCase(
            repository: MockWorkSpaceRepository(
                basicFolderBehavior: .success(Folder(path: URL(fileURLWithPath: "/"), name: "test"))
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

    /// 취소 Case (During Execution): 작업 도중 Task가 취소된 경우
    func test_execute_throwsCancelled_whenTaskIsCancelledDuringExecution() async {
        // Given
        let useCase = DefaultFetchBasicFolderUseCase(
            repository: MockWorkSpaceRepository(
                basicFolderBehavior: .success(Folder(path: URL(fileURLWithPath: "/"), name: "test")),
                rootUrlDelay: 100_000_000 // 0.1초 지연
            )
        )

        // When & Then
        let task = Task { try await useCase.execute() }

        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05초 대기 후 취소
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("작업 도중 취소되었으므로 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }
}
