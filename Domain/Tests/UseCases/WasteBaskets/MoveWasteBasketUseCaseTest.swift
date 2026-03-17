@testable import Domain
import XCTest

final class MoveWasteBasketUseCaseTest: XCTestCase {
    typealias UseCaseError = MoveWasteBasketUseCaseError
}

// MARK: - 성공 케이스

extension MoveWasteBasketUseCaseTest {
    func test_정상상태_항목을휴지통으로이동시_리포지토리의이동메서드를호출한다() async throws {
        // Given
        let item: WasteBasketItem = .folder(id: UUID())
        let repository = MockWasteBasketRepository()
        await repository.setMoveResult(.success(()))
        await repository.expectMoveToWasteBasket(item: item, callCount: 1)

        let useCase = DefaultMoveWasteBasketUseCase(repository: repository)

        // When
        try await useCase.execute(method: .single(item: item))

        // Then
        await repository.verify()
    }
}

// MARK: - 에러 케이스

extension MoveWasteBasketUseCaseTest {
    func test_리포지토리이동실패상태_항목을휴지통으로이동시_moveFailed에러를던진다() async {
        // Given
        let item: WasteBasketItem = .folder(id: UUID())
        let method = MoveWasteBasketMethod.single(item: item)
        let repository = MockWasteBasketRepository()
        await repository.setMoveResult(.failure(.moveFailed(method)))
        await repository.expectMoveToWasteBasket(item: item, callCount: 1)

        let useCase = DefaultMoveWasteBasketUseCase(repository: repository)

        // When & Then
        do {
            try await useCase.execute(method: method)
            XCTFail("에러가 발생해야 합니다.")
        } catch UseCaseError.moveFailed(let failedMethod) {
            XCTAssertEqual(failedMethod, method)
            await repository.verify()
        } catch {
            XCTFail("Expected .moveFailed, got \(error)")
        }
    }

    func test_리포지토리알수없는에러상태_항목을휴지통으로이동시_unknown에러를던진다() async {
        // Given
        let item: WasteBasketItem = .folder(id: UUID())
        let method = MoveWasteBasketMethod.single(item: item)
        struct Dummy: Error {}
        let dummyError = Dummy()
        let repository = MockWasteBasketRepository()
        await repository.setMoveResult(.failure(.unknown(dummyError)))
        await repository.expectMoveToWasteBasket(item: item, callCount: 1)

        let useCase = DefaultMoveWasteBasketUseCase(repository: repository)

        // When & Then
        do {
            try await useCase.execute(method: method)
            XCTFail("에러가 발생해야 합니다.")
        } catch UseCaseError.unknown(let error) {
            XCTAssertTrue(error is MoveWasteBasketRepositoryError)
            await repository.verify()
        } catch {
            XCTFail("Expected .unknown, got \(error)")
        }
    }

    func test_작업취소상태_항목을휴지통으로이동시_cancelled에러를던진다() async {
        // Given
        let item: WasteBasketItem = .folder(id: UUID())
        let method = MoveWasteBasketMethod.single(item: item)
        let repository = MockWasteBasketRepository()
        await repository.setMoveResult(.failure(.cancelled))
        await repository.expectMoveToWasteBasket(item: item, callCount: 1)

        let useCase = DefaultMoveWasteBasketUseCase(repository: repository)

        // When & Then
        do {
            try await useCase.execute(method: method)
            XCTFail("에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            await repository.verify()
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }
}

// MARK: - 취소 케이스

extension MoveWasteBasketUseCaseTest {
    func test_태스크이미취소상태_항목을휴지통으로이동시_즉시cancelled에러를던진다() async {
        // Given
        let item: WasteBasketItem = .folder(id: UUID())
        let repository = MockWasteBasketRepository()
        await repository.setMoveResult(.success(()))
        await repository.expectMoveToWasteBasket(callCount: 0)

        let useCase = DefaultMoveWasteBasketUseCase(repository: repository)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await useCase.execute(method: .single(item: item))
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
