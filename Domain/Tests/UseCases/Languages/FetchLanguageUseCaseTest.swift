@testable import Domain
import XCTest

final class FetchLanguageUseCaseTest: XCTestCase {}

// MARK: - 성공 케이스

extension FetchLanguageUseCaseTest {
    func test_정상상태_언어조회시_설정된Language를반환한다() async throws {
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

// MARK: - 에러 케이스

extension FetchLanguageUseCaseTest {
    func test_데이터미존재상태_언어조회시_notFound에러를던진다() async {
        // Given
        let repository = MockLanguageRepository()
        await repository.setFetchResult(.failure(.notFound))
        await repository.expectFetch(callCount: 1)

        let useCase = DefaultFetchLanguageUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("Repository가 notFound 에러를 던지면 UseCase도 notFound 에러를 던져야 합니다.")
        } catch FetchLanguagesUseCaseError.notFound {
            // Success
            await repository.verify()
        } catch {
            XCTFail("Expected .notFound, got \(error)")
        }
    }

    func test_조회중취소상태_언어조회시_cancelled에러를던진다() async {
        // Given
        let repository = MockLanguageRepository()
        await repository.setFetchResult(.failure(.cancelled))
        await repository.expectFetch(callCount: 1)

        let useCase = DefaultFetchLanguageUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("Repository가 cancelled 에러를 던지면 UseCase도 cancelled 에러를 던져야 합니다.")
        } catch FetchLanguagesUseCaseError.cancelled {
            // Success
            await repository.verify()
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }

    func test_태스크이미취소상태_언어조회시_즉시cancelled에러를던진다() async {
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
        } catch FetchLanguagesUseCaseError.cancelled {
            // Success
            await repository.verify()
        } catch {
            XCTFail("Expected FetchLanguagesUseCaseError.cancelled, got \(error)")
        }
    }

    func test_알수없는에러발생상태_언어조회시_unknown에러를던진다() async {
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
        } catch FetchLanguagesUseCaseError.unknown(let repoError) {
            XCTAssertTrue(repoError is Dummy)
            await repository.verify()
        } catch {
            XCTFail("Expected .unknown, got \(error)")
        }
    }
}
