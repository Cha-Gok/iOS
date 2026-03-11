import XCTest
@testable import Domain

final class FetchRootUrlUseCaseTest: XCTestCase {
    typealias UseCaseError = FetchRootUrlUseCaseError
}

// MARK: - Success Cases

extension FetchRootUrlUseCaseTest {
    /// 성공 Case: Repository가 정상적으로 URL을 반환할 때
    /// UseCase도 해당 URL을 반환하는지 확인
    func test_execute_returnsURL_whenRepositorySucceeds() async throws {
        // Given
        let expectedURL = URL.applicationSupportDirectory
        let useCase = DefaultFetchRootUrlUseCase(
            repository: MockWorkSpaceRepository(
                rootUrlBehavior: .success(expectedURL)
            )
        )

        // When
        let url = try await useCase.execute()

        // Then
        XCTAssertEqual(url, expectedURL)
    }
}

// MARK: - Error Cases

extension FetchRootUrlUseCaseTest {

    /// 취소 Case (Repository): Repository 단계에서 cancelled 에러가 발생한 경우
    /// UseCase가 .cancelled 에러를 던지는지 확인
    func test_execute_throwsCancelled_whenRepositoryReturnsCancelled() async {
        // Given
        let useCase = DefaultFetchRootUrlUseCase(
            repository: MockWorkSpaceRepository(
                rootUrlBehavior: .cancelled
            )
        )

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("Repository가 cancelled 에러를 던지면 UseCase도 cancelled 에러를 던져야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }

    func test_execute_throwsCancelled_whenTaskIsCancelledPreemptively() async {
        // Given
        let testURL: URL = .applicationSupportDirectory
        let useCase = DefaultFetchRootUrlUseCase(
            repository: MockWorkSpaceRepository(
                rootUrlBehavior: .success(testURL)
            )
        )

        // When & Then
        let task = Task { try await useCase.execute() }
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("이미 취소된 Task이므로 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
        } catch {
            XCTFail("Expected FetchRootUrlUseCaseError.cancelled, got \(error)")
        }
    }

    /// 취소 Case (During Execution): Repository가 작업 중일 때 Task가 취소된 경우
    /// Repository 또는 UseCase에서 .cancelled 에러를 올바르게 전파하는지 확인
    func test_execute_throwsCancelled_whenTaskIsCancelledDuringExecution() async {
        // Given
        let testURL: URL = .applicationSupportDirectory
        let useCase = DefaultFetchRootUrlUseCase(
            repository: MockWorkSpaceRepository(
                rootUrlBehavior: .success(testURL),
                rootUrlDelay: 100_000_000 // 0.1초 지연
            )
        )

        // When & Then
        let task = Task { try await useCase.execute() }

        // 작업을 시작할 시간을 조금 준 뒤 취소
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05초 대기
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("작업 도중 취소되었으므로 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
        } catch {
            XCTFail("Expected FetchRootUrlUseCaseError.cancelled, got \(error)")
        }
    }

    /// 알 수 없는 에러 Case: Repository에서 정의되지 않은 에러를 던졌을 때
    /// UseCase가 이를 .unknown 케이스로 래핑하여 던지는지 확인
    func test_execute_throwsUnknown_whenRepositoryThrowsUnknown() async {
        // Given
        struct Dummy: Error {}
        let dummyError = Dummy()
        let useCase = DefaultFetchRootUrlUseCase(
            repository: MockWorkSpaceRepository(
                rootUrlBehavior: .unknown(dummyError)
            )
        )

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("Repository가 unknown 에러를 던지면 UseCase도 .unknown 에러를 던져야 합니다.")
        } catch let error {
            switch error {
                case .unknown(let repoError):
                    XCTAssertTrue(repoError is Dummy)
                default:
                    XCTFail("Expected .unknown, got \(error)")
            }
        }
    }
}
