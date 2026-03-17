@testable import Domain
import XCTest

final class FetchWasteBasketFolderUseCaseTest: XCTestCase {
    typealias UseCaseError = FetchWasteBasketFolderUseCaseError
}

// MARK: - 성공 케이스

extension FetchWasteBasketFolderUseCaseTest {
    func test_정상상태_휴지통항목조회시_전체항목목록을반환한다() async throws {
        // Given
        let expectedItems: [WasteBasketItem] = [
            .folder(id: UUID()),
            .voiceNote(id: UUID())
        ]
        let repository = MockWasteBasketRepository()
        await repository.setFetchAllResult(.success(expectedItems))
        await repository.expectFetchAll(callCount: 1)

        let useCase = DefaultFetchWasteBasketFolderUseCase(repository: repository)

        // When
        let result = try await useCase.execute()

        // Then
        XCTAssertEqual(result, expectedItems)
        await repository.verify()
    }

    func test_데이터미존재상태_휴지통항목조회시_빈배열을반환한다() async throws {
        // Given
        let repository = MockWasteBasketRepository()
        await repository.setFetchAllResult(.success([]))
        await repository.expectFetchAll(callCount: 1)

        let useCase = DefaultFetchWasteBasketFolderUseCase(repository: repository)

        // When
        let result = try await useCase.execute()

        // Then
        XCTAssertTrue(result.isEmpty)
        await repository.verify()
    }
}

// MARK: - 에러 케이스

extension FetchWasteBasketFolderUseCaseTest {
    func test_리포지토리조회실패상태_휴지통항목조회시_fetchFailed에러를던진다() async {
        // Given
        let repository = MockWasteBasketRepository()
        await repository.setFetchAllResult(.failure(.fetchFailed))
        await repository.expectFetchAll(callCount: 1)

        let useCase = DefaultFetchWasteBasketFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("에러가 발생해야 합니다.")
        } catch UseCaseError.fetchFailed {
            await repository.verify()
        } catch {
            XCTFail("Expected .fetchFailed, got \(error)")
        }
    }

    func test_리포지토리알수없는에러상태_휴지통항목조회시_unknown에러를던진다() async {
        // Given
        struct Dummy: Error {}
        let dummyError = Dummy()
        let repository = MockWasteBasketRepository()
        await repository.setFetchAllResult(.failure(.unknown(dummyError)))
        await repository.expectFetchAll(callCount: 1)

        let useCase = DefaultFetchWasteBasketFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("에러가 발생해야 합니다.")
        } catch UseCaseError.unknown(let error) {
            XCTAssertTrue(error is Dummy)
            await repository.verify()
        } catch {
            XCTFail("Expected .unknown, got \(error)")
        }
    }
}

// MARK: - 취소 케이스

extension FetchWasteBasketFolderUseCaseTest {
    func test_작업취소상태_휴지통항목조회시_cancelled에러를던진다() async {
        // Given
        let repository = MockWasteBasketRepository()
        await repository.setFetchAllResult(.failure(.cancelled))
        await repository.expectFetchAll(callCount: 1)

        let useCase = DefaultFetchWasteBasketFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            await repository.verify()
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }

    func test_태스크이미취소상태_휴지통항목조회시_즉시cancelled에러를던진다() async {
        // Given
        let repository = MockWasteBasketRepository()
        await repository.setFetchAllResult(.success([]))
        await repository.expectFetchAll(callCount: 0)

        let useCase = DefaultFetchWasteBasketFolderUseCase(repository: repository)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await useCase.execute()
        }

        do {
            _ = try await task.value
            XCTFail("작업이 취소되어야 합니다.")
        } catch UseCaseError.cancelled {
            await repository.verify()
        } catch {
            XCTFail("Expected .cancelled error, but got \(error)")
        }
    }
}
