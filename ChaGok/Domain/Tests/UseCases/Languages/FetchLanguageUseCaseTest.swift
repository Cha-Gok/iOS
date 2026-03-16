import XCTest
@testable import Domain

final class FetchLanguageUseCaseTest: XCTestCase {
    typealias UseCaseError = FetchLanguagesUseCaseError
}

// MARK: - Success Cases

extension FetchLanguageUseCaseTest {

    func test_execute_언어조회에성공하면_Language를반환한다() async throws {
        // Given
        let expectedLanguage: Language = .ko
        let repository = MockLanguageRepository()
        await repository.setFetchResult(.success(expectedLanguage))
        await repository.expectFetch(callCount: 1)

        let useCase = DefaultFetchLanguageUseCase(repository: repository)

        // When
        let result = try await useCase.execute()

        // Then
        XCTAssertEqual(result, expectedLanguage)
        await repository.verify()
    }
}

// MARK: - Error Cases

extension FetchLanguageUseCaseTest {

    func test_execute_언어조회실패시_notFound에러를던진다() async {
        // Given
        let repository = MockLanguageRepository()
        await repository.setFetchResult(.failure(.notFound))
        await repository.expectFetch(callCount: 1)

        let useCase = DefaultFetchLanguageUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("Repository가 notFound 에러를 던지면 UseCase도 notFound 에러를 던져야 합니다.")
        } catch UseCaseError.notFound {
            // Success
            await repository.verify()
        } catch {
            XCTFail("Expected .notFound, got \(error)")
        }
    }

    func test_execute_언어조회중취소되면_cancelled에러를던진다() async {
        // Given
        let repository = MockLanguageRepository()
        await repository.setFetchResult(.failure(.cancelled))
        await repository.expectFetch(callCount: 1)

        let useCase = DefaultFetchLanguageUseCase(repository: repository)

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

    func test_execute_언어조회작업이이미취소되었으면_즉시cancelled에러를던진다() async {
        // Given
        let expectedLanguage: Language = .ko
        let repository = MockLanguageRepository()
        await repository.setFetchResult(.success(expectedLanguage))
        await repository.expectFetch(callCount: 0)

        let useCase = DefaultFetchLanguageUseCase(repository: repository)

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
            XCTFail("Expected FetchLanguagesUseCaseError.cancelled, got \(error)")
        }
    }

    func test_execute_언어조회중알수없는에러가발생하면_unknown에러를던진다() async {
        // Given
        struct Dummy: Error {}
        let dummyError = Dummy()
        let repository = MockLanguageRepository()
        await repository.setFetchResult(.failure(.unknown(dummyError)))
        await repository.expectFetch(callCount: 1)

        let useCase = DefaultFetchLanguageUseCase(repository: repository)

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
