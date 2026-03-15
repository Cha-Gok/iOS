import XCTest
@testable import Domain

final class SetLanguageUseCaseTest: XCTestCase {
    typealias UseCaseError = SetLanguagesUseCaseError
}

// MARK: - Success Cases

extension SetLanguageUseCaseTest {

    func test_execute_언어설정에성공하면_정상종료된다() async throws {
        // Given
        let repository = MockLanguageRepository()
        await repository.setSelectResult(.success(()))
        await repository.expectSelect(callCount: 1)

        let useCase = DefaultSelectLanguageUseCase(repository: repository)

        // When
        try await useCase.execute(lang: .ko)

        // Then
        await repository.verify()
    }
}

// MARK: - Error Cases

extension SetLanguageUseCaseTest {

    func test_execute_언어설정실패시_saveFailed에러를던진다() async {
        // Given
        let repository = MockLanguageRepository()
        await repository.setSelectResult(.failure(.saveFailed))
        await repository.expectSelect(callCount: 1)

        let useCase = DefaultSelectLanguageUseCase(repository: repository)

        // When & Then
        do {
            try await useCase.execute(lang: .ko)
            XCTFail("Repository가 saveFailed 에러를 던지면 UseCase도 saveFailed 에러를 던져야 합니다.")
        } catch UseCaseError.saveFailed {
            // Success
            await repository.verify()
        } catch {
            XCTFail("Expected .saveFailed, got \(error)")
        }
    }

    func test_execute_언어설정중취소되면_cancelled에러를던진다() async {
        // Given
        let repository = MockLanguageRepository()
        await repository.setSelectResult(.failure(.cancelled))
        await repository.expectSelect(callCount: 1)

        let useCase = DefaultSelectLanguageUseCase(repository: repository)

        // When & Then
        do {
            try await useCase.execute(lang: .ko)
            XCTFail("Repository가 cancelled 에러를 던지면 UseCase도 cancelled 에러를 던져야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
            await repository.verify()
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }

    func test_execute_언어설정작업이이미취소되었으면_즉시cancelled에러를던진다() async {
        // Given
        let repository = MockLanguageRepository()
        await repository.setSelectResult(.success(()))
        await repository.expectSelect(callCount: 0)

        let useCase = DefaultSelectLanguageUseCase(repository: repository)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await useCase.execute(lang: .ko)
        }

        do {
            try await task.value
            XCTFail("이미 취소된 Task이므로 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
            await repository.verify()
        } catch {
            XCTFail("Expected SetLanguagesUseCaseError.cancelled, got \(error)")
        }
    }

    func test_execute_언어설정중알수없는에러가발생하면_unknown에러를던진다() async {
        // Given
        struct Dummy: Error {}
        let dummyError = Dummy()
        let repository = MockLanguageRepository()
        await repository.setSelectResult(.failure(.unknown(dummyError)))
        await repository.expectSelect(callCount: 1)

        let useCase = DefaultSelectLanguageUseCase(repository: repository)

        // When & Then
        do {
            try await useCase.execute(lang: .ko)
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
