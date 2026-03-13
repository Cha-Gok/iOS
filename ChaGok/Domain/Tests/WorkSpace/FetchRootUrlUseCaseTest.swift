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
        let repository = MockWorkSpaceRepository(
            rootUrlBehavior: .success(expectedURL)
        )
        let useCase = DefaultFetchRootUrlUseCase(repository: repository)

        // When
        let url = try await useCase.execute()

        // Then
        XCTAssertEqual(url, expectedURL)
        let callCount = await repository.fetchRootURLCallCount
        XCTAssertEqual(callCount, 1, "성공 시 Repository가 한 번 호출되어야 합니다.")
    }
}

// MARK: - Error Cases

extension FetchRootUrlUseCaseTest {

    /// 취소 Case (Repository): Repository 단계에서 cancelled 에러가 발생한 경우
    /// UseCase가 .cancelled 에러를 던지는지 확인
    func test_execute_throwsCancelled_whenRepositoryReturnsCancelled() async {
        // Given
        let repository = MockWorkSpaceRepository(rootUrlBehavior: .cancelled)
        let useCase = DefaultFetchRootUrlUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("Repository가 cancelled 에러를 던지면 UseCase도 cancelled 에러를 던져야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
            let callCount = await repository.fetchRootURLCallCount
            XCTAssertEqual(callCount, 1, "Repository까지 진입 후 취소된 경우 호출 횟수는 1회여야 합니다.")
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }

    /// 취소 Case: 즉시 취소된경우
    ///  UserCase의 isCancelled가 있는지 확인
    func test_execute_throwsCancelled_whenTaskIsCancelledPreemptively() async {
        // Given
        let testURL: URL = .applicationSupportDirectory
        let repository = MockWorkSpaceRepository(rootUrlBehavior: .success(testURL))
        let useCase = DefaultFetchRootUrlUseCase(repository: repository)

        // When & Then
        let task = Task { try await useCase.execute() }
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("이미 취소된 Task이므로 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
            let callCount = await repository.fetchRootURLCallCount
            XCTAssertEqual(callCount, 0, "선제적 취소 시 Repository는 단 한 번도 호출되지 않아야 합니다.")
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
        let repository = MockWorkSpaceRepository(rootUrlBehavior: .unknown(dummyError))
        let useCase = DefaultFetchRootUrlUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("Repository가 unknown 에러를 던지면 UseCase도 .unknown 에러를 던져야 합니다.")
        } catch let error {
            switch error {
                case .unknown(let repoError):
                    XCTAssertTrue(repoError is Dummy)
                    let callCount = await repository.fetchRootURLCallCount
                    XCTAssertEqual(callCount, 1, "에러 발생 시에도 Repository 호출은 1회 발생해야 합니다.")
                default:
                    XCTFail("Expected .unknown, got \(error)")
            }
        }
    }
}
