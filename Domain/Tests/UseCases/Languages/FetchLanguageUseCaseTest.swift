@testable import Domain
import Core
import XCTest

final class FetchLanguageUseCaseTest: XCTestCase {}

// MARK: - 성공 케이스

extension FetchLanguageUseCaseTest {
    func test_정상상태_언어조회시_설정된Language를반환한다() async throws {
        let repository = MockLanguageRepository()
        let sut = DefaultFetchLanguageUseCase(repository: repository)

        // Given
        let expectedLanguage: Language = .ko
        await repository.setFetchResult(.success(expectedLanguage))
        await repository.expectFetch(callCount: 1)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result, expectedLanguage)
        await repository.verify()
    }
}

// MARK: - 에러 케이스

extension FetchLanguageUseCaseTest {
    func test_데이터미존재상태_언어조회시_notFound에러를던진다() async {
        let repository = MockLanguageRepository()
        let sut = DefaultFetchLanguageUseCase(repository: repository)

        // Given
        await repository.setFetchResult(.failure(.notFound))
        await repository.expectFetch(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("FetchLanguagesUseCaseError.notFound 에러를 throw 해야 합니다.")
        } catch {
            guard case .notFound = error else {
                return XCTFail(
                    "예상한 에러는 FetchLanguagesUseCaseError.notFound 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
        await repository.verify()
    }

    func test_알수없는에러발생상태_언어조회시_unknown에러를던진다() async {
        let repository = MockLanguageRepository()
        let sut = DefaultFetchLanguageUseCase(repository: repository)

        // Given
        struct DummyError: Error {}
        await repository.setFetchResult(.failure(.unknown(DummyError())))
        await repository.expectFetch(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("FetchLanguagesUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let repoError) = error else {
                return XCTFail(
                    "예상한 에러는 FetchLanguagesUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
            XCTAssertTrue(repoError is DummyError)
        }
        await repository.verify()
    }
}

// MARK: - 취소 케이스

extension FetchLanguageUseCaseTest {
    func test_조회중취소상태_언어조회시_cancelled에러를던진다() async {
        let repository = MockLanguageRepository()
        let sut = DefaultFetchLanguageUseCase(repository: repository)

        // Given
        await repository.setFetchResult(.failure(.cancelled))
        await repository.expectFetch(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("FetchLanguagesUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error else {
                return XCTFail(
                    "예상한 에러는 FetchLanguagesUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
        await repository.verify()
    }

    func test_태스크이미취소상태_언어조회시_즉시cancelled에러를던진다() async {
        let repository = MockLanguageRepository()
        let sut = DefaultFetchLanguageUseCase(repository: repository)

        // Given
        let expectedLanguage: Language = .ko
        await repository.setFetchResult(.success(expectedLanguage))
        await repository.expectFetch(callCount: 0)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await sut.execute()
        }

        do {
            _ = try await task.value
            XCTFail("FetchLanguagesUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? FetchLanguagesUseCaseError else {
                return XCTFail(
                    "예상한 에러는 FetchLanguagesUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
        await repository.verify()
    }
}
