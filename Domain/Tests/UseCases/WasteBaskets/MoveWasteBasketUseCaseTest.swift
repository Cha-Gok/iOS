@testable import Domain
import XCTest

final class MoveWasteBasketUseCaseTest: XCTestCase {
    typealias UseCaseError = MoveWasteBasketUseCaseError
}

// MARK: - Success Cases

extension MoveWasteBasketUseCaseTest {
    func test_휴지통_이동_다중이동_성공_리포지토리를호출한다() async throws {
        // Given
        let items: [WasteBasketItem] = [
            .folder(id: UUID()),
            .voiceNote(id: UUID())
        ]
        let repository = MockWasteBasketRepository()
        await repository.setMoveResult(.success(()))
        await repository.expectMoveAllToWasteBasket(items: items, callCount: 1)

        let useCase = DefaultMoveWasteBasketUseCase(repository: repository)

        // When
        _ = try await useCase.execute(method: .multiple(items: items))

        // Then
        await repository.verify()
    }

    func test_휴지통_이동_단일이동_성공_리포지토리를호출한다() async throws {
        // Given
        let item: WasteBasketItem = .folder(id: UUID())
        let repository = MockWasteBasketRepository()
        await repository.setMoveResult(.success(()))
        await repository.expectMoveToWasteBasket(item: item, callCount: 1)

        let useCase = DefaultMoveWasteBasketUseCase(repository: repository)

        // When
        _ = try await useCase.execute(method: .single(item: item))

        // Then
        await repository.verify()
    }
}

// MARK: - Error Mapping Cases

extension MoveWasteBasketUseCaseTest {
    func test_휴지통_이동_리포지토리이동실패시_moveFailed에러를던진다() async {
        // Given
        let method = MoveWasteBasketMethod.single(item: .folder(id: UUID()))
        let repository = MockWasteBasketRepository()
        await repository.setMoveResult(.failure(.moveFailed(method)))
        await repository.expectMoveToWasteBasket(callCount: 1)

        let useCase = DefaultMoveWasteBasketUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(method: method)
            XCTFail("에러가 발생해야 합니다.")
        } catch UseCaseError.moveFailed(let failedMethod) {
            XCTAssertEqual(failedMethod, method)
            await repository.verify()
        } catch {
            XCTFail("Expected .moveFailed, got \(error)")
        }
    }

    func test_휴지통_이동_리포지토리다중이동실패시_moveFailed에러를던진다() async {
        // Given
        let items: [WasteBasketItem] = [.folder(id: UUID())]
        let method = MoveWasteBasketMethod.multiple(items: items)
        let repository = MockWasteBasketRepository()
        await repository.setMoveResult(.failure(.moveFailed(method)))
        await repository.expectMoveAllToWasteBasket(callCount: 1)

        let useCase = DefaultMoveWasteBasketUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(method: method)
            XCTFail("에러가 발생해야 합니다.")
        } catch UseCaseError.moveFailed(let failedMethod) {
            XCTAssertEqual(failedMethod, method)
            await repository.verify()
        } catch {
            XCTFail("Expected .moveFailed, got \(error)")
        }
    }

    func test_휴지통_이동_리포지토리알수없는에러시_unknown에러를던진다() async {
        // Given
        let item: WasteBasketItem = .folder(id: UUID())
        struct Dummy: Error {}
        let dummyError = Dummy()
        let repository = MockWasteBasketRepository()
        await repository.setMoveResult(.failure(.unknown(dummyError)))
        await repository.expectMoveToWasteBasket(callCount: 1)

        let useCase = DefaultMoveWasteBasketUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(method: .single(item: item))
            XCTFail("에러가 발생해야 합니다.")
        } catch UseCaseError.unknown(let error) {
            XCTAssertTrue(error is Dummy)
            await repository.verify()
        } catch {
            XCTFail("Expected .unknown, got \(error)")
        }
    }

    func test_휴지통_이동_리포지토리취소시_cancelled에러를던진다() async {
        // Given
        let item: WasteBasketItem = .folder(id: UUID())
        let repository = MockWasteBasketRepository()
        await repository.setMoveResult(.failure(.cancelled))
        await repository.expectMoveToWasteBasket(callCount: 1)

        let useCase = DefaultMoveWasteBasketUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(method: .single(item: item))
            XCTFail("에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            await repository.verify()
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }
}

// MARK: - Cancellation Case

extension MoveWasteBasketUseCaseTest {
    func test_휴지통_이동_작업전_즉시cancelled에러를던진다() async {
        // Given
        let item: WasteBasketItem = .folder(id: UUID())
        let repository = MockWasteBasketRepository()
        await repository.setMoveResult(.success(()))
        await repository.expectMoveToWasteBasket(callCount: 0)

        let useCase = DefaultMoveWasteBasketUseCase(repository: repository)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await useCase.execute(method: .single(item: item))
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
