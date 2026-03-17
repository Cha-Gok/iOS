@testable import Domain
import XCTest

final class SetLanguageUseCaseTest: XCTestCase {
    typealias UseCaseError = SetLanguagesUseCaseError
}

// MARK: - 성공 케이스

extension SetLanguageUseCaseTest {
    func test_정상상태_언어설정시_리포지토리의저장메서드를호출한다() async throws {
        // Given
        let repository = MockLanguageRepository()
        await repository.setSaveResult(.success(()))
        await repository.expectSave(language: .ko, callCount: 1)

        let useCase = DefaultSelectLanguageUseCase(repository: repository)

        // When
        try await useCase.execute(lang: .ko)

        // Then
        await repository.verify()
    }
}

// MARK: - 에러 케이스

extension SetLanguageUseCaseTest {
    func test_리포지토리저장실패상태_언어설정시_saveFailed에러를던진다() async {
        // Given
        let repository = MockLanguageRepository()
        await repository.setSaveResult(.failure(.saveFailed))
        await repository.expectSave(language: .ko, callCount: 1)

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

    func test_조회중취소상태_언어설정시_cancelled에러를던진다() async {
        // Given
        let repository = MockLanguageRepository()
        await repository.setSaveResult(.failure(.cancelled))
        await repository.expectSave(language: .ko, callCount: 1)

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

    func test_태스크이미취소상태_언어설정시_즉시cancelled에러를던진다() async {
        // Given
        let repository = MockLanguageRepository()
        await repository.setSaveResult(.success(()))
        await repository.expectSave(callCount: 0)

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

    func test_알수없는에러발생상태_언어설정시_unknown에러를던진다() async {
        // Given
        struct Dummy: Error {}
        let dummyError = Dummy()
        let repository = MockLanguageRepository()
        await repository.setSaveResult(.failure(.unknown(dummyError)))
        await repository.expectSave(language: .ko, callCount: 1)

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
