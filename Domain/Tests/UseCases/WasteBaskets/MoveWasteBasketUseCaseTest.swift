@testable import Domain
import Core
import XCTest

final class MoveWasteBasketUseCaseTest: XCTestCase {}

// MARK: - 성공 케이스

extension MoveWasteBasketUseCaseTest {
    func test_정상상태_항목을휴지통으로이동시_리포지토리의이동메서드를호출한다() async throws {
        let wasteBasketRepository = MockWasteBasketRepository()
        let sut = DefaultMoveWasteBasketUseCase(repository: wasteBasketRepository)

        // Given
        let item: WasteBasketItem = .folder(id: UUID())
        await wasteBasketRepository.setMoveResult(.success(()))
        await wasteBasketRepository.expectMoveToWasteBasket(item: item, callCount: 1)

        // When
        try await sut.execute(method: .single(item: item))

        // Then
        await wasteBasketRepository.verify()
    }
}

// MARK: - 에러 케이스

extension MoveWasteBasketUseCaseTest {
    func test_리포지토리이동실패상태_항목을휴지통으로이동시_moveFailed에러를던진다() async {
        let wasteBasketRepository = MockWasteBasketRepository()
        let sut = DefaultMoveWasteBasketUseCase(repository: wasteBasketRepository)

        // Given
        let item: WasteBasketItem = .folder(id: UUID())
        let method = MoveWasteBasketMethod.single(item: item)
        await wasteBasketRepository.setMoveResult(.failure(.moveFailed(method)))
        await wasteBasketRepository.expectMoveToWasteBasket(item: item, callCount: 1)

        // When & Then
        do {
            try await sut.execute(method: method)
            XCTFail("MoveWasteBasketUseCaseError.moveFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .moveFailed(let failedMethod) = error else {
                return XCTFail(
                    "예상한 에러는 MoveWasteBasketUseCaseError.moveFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
            XCTAssertEqual(failedMethod, method)
        }
        await wasteBasketRepository.verify()
    }

    func test_리포지토리알수없는에러상태_항목을휴지통으로이동시_unknown에러를던진다() async {
        let wasteBasketRepository = MockWasteBasketRepository()
        let sut = DefaultMoveWasteBasketUseCase(repository: wasteBasketRepository)

        // Given
        let item: WasteBasketItem = .folder(id: UUID())
        let method = MoveWasteBasketMethod.single(item: item)
        struct DummyError: Error {}
        let expectedError = DummyError()
        await wasteBasketRepository.setMoveResult(.failure(.unknown(expectedError)))
        await wasteBasketRepository.expectMoveToWasteBasket(item: item, callCount: 1)

        // When & Then
        do {
            try await sut.execute(method: method)
            XCTFail("MoveWasteBasketUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let underlyingError) = error else {
                return XCTFail(
                    "예상한 에러는 MoveWasteBasketUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
            XCTAssertTrue(underlyingError is DummyError)
        }
        await wasteBasketRepository.verify()
    }

    func test_작업취소상태_항목을휴지통으로이동시_cancelled에러를던진다() async {
        let wasteBasketRepository = MockWasteBasketRepository()
        let sut = DefaultMoveWasteBasketUseCase(repository: wasteBasketRepository)

        // Given
        let item: WasteBasketItem = .folder(id: UUID())
        let method = MoveWasteBasketMethod.single(item: item)
        await wasteBasketRepository.setMoveResult(.failure(.cancelled))
        await wasteBasketRepository.expectMoveToWasteBasket(item: item, callCount: 1)

        // When & Then
        do {
            try await sut.execute(method: method)
            XCTFail("MoveWasteBasketUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error else {
                return XCTFail(
                    "예상한 에러는 MoveWasteBasketUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
        await wasteBasketRepository.verify()
    }
}

// MARK: - 취소 케이스

extension MoveWasteBasketUseCaseTest {
    func test_태스크이미취소상태_항목을휴지통으로이동시_즉시cancelled에러를던진다() async {
        let wasteBasketRepository = MockWasteBasketRepository()
        let sut = DefaultMoveWasteBasketUseCase(repository: wasteBasketRepository)

        // Given
        let item: WasteBasketItem = .folder(id: UUID())
        let method = MoveWasteBasketMethod.single(item: item)
        await wasteBasketRepository.setMoveResult(.success(()))
        await wasteBasketRepository.expectMoveToWasteBasket(callCount: 0)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await sut.execute(method: method)
        }

        do {
            try await task.value
            XCTFail("MoveWasteBasketUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? MoveWasteBasketUseCaseError else {
                return XCTFail(
                    "예상한 에러는 MoveWasteBasketUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
        await wasteBasketRepository.verify()
    }
}
