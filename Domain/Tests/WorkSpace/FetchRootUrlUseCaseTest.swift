@testable import Domain
import XCTest

final class FetchRootUrlUseCaseTest: XCTestCase {
    typealias UseCaseError = FetchRootUrlUseCaseError
}

// MARK: - Success Cases

extension FetchRootUrlUseCaseTest {
    func test_execute_루트URL조회에성공하면_URL을반환한다() async throws {
        // Given
        let expectedURL = URL.applicationSupportDirectory
        let repository = MockWorkSpaceRepository()
        await repository.setRootURLResult(.success(expectedURL))
        await repository.expectFetchRootURL(callCount: 1)

        let useCase = DefaultFetchRootUrlUseCase(repository: repository)

        // When
        let url = try await useCase.execute()

        // Then
        XCTAssertEqual(url, expectedURL)
        await repository.verify()
    }
}

// MARK: - Error Cases

extension FetchRootUrlUseCaseTest {
    func test_execute_루트URL조회중취소되면_cancelled에러를던진다() async {
        // Given
        let repository = MockWorkSpaceRepository()
        await repository.setRootURLResult(.failure(.cancelled))
        await repository.expectFetchRootURL(callCount: 1)

        let useCase = DefaultFetchRootUrlUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("Repository가 cancelled 에러를 던지면 UseCase도 cancelled 에러를 던져야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
            await repository.verify()
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }

    func test_execute_루트URL조회작업이이미취소되었으면_즉시cancelled에러를던진다() async {
        // Given
        let testURL: URL = .applicationSupportDirectory
        let repository = MockWorkSpaceRepository()
        await repository.setRootURLResult(.success(testURL))
        await repository.expectFetchRootURL(callCount: 0)

        let useCase = DefaultFetchRootUrlUseCase(repository: repository)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await useCase.execute()
        }

        do {
            _ = try await task.value
            XCTFail("이미 취소된 Task이므로 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
            await repository.verify()
        } catch {
            XCTFail("Expected FetchRootUrlUseCaseError.cancelled, got \(error)")
        }
    }

    func test_execute_루트URL조회중알수없는에러가발생하면_unknown에러를던진다() async {
        // Given
        struct Dummy: Error {}
        let dummyError = Dummy()
        let repository = MockWorkSpaceRepository()
        await repository.setRootURLResult(.failure(.unknown(dummyError)))
        await repository.expectFetchRootURL(callCount: 1)

        let useCase = DefaultFetchRootUrlUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("Repository가 unknown 에러를 던지면 UseCase도 .unknown 에러를 던져야 합니다.")
        } catch {
            switch error {
            case .unknown(let repoError):
                XCTAssertTrue(repoError is Dummy)
                await repository.verify()
            default:
                XCTFail("Expected .unknown, got \(error)")
            }
        }
    }
}
