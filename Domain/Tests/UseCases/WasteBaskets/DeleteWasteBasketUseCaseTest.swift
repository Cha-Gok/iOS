@testable import Domain
import XCTest

final class DeleteWasteBasketUseCaseTest: XCTestCase {
    typealias UseCaseError = DeleteWasteBasketUseCaseError
}

// MARK: - 성공 케이스

extension DeleteWasteBasketUseCaseTest {
    func test_정상상태_휴지통비우기시_리포지토리의비우기메서드를호출한다() async throws {
        // Given
        let repository = MockWasteBasketRepository()
        await repository.setDeleteResult(.success(()))
        await repository.expectAllClear(callCount: 1)

        let useCase = DefaultDeleteWasteBasketUseCase(repository: repository)

        // When
        _ = try await useCase.execute(method: .all)

        // Then
        await repository.verify()
    }

    func test_정상상태_휴지통다중삭제시_리포지토리의다중삭제메서드를호출한다() async throws {
        // Given
        let items: [WasteBasketItem] = [
            .folder(id: UUID()),
            .voiceNote(id: UUID())
        ]
        let repository = MockWasteBasketRepository()
        await repository.setDeleteResult(.success(()))
        await repository.expectDeleteAll(items: items, callCount: 1)

        let useCase = DefaultDeleteWasteBasketUseCase(repository: repository)

        // When
        _ = try await useCase.execute(method: .multiple(items: items))

        // Then
        await repository.verify()
    }

    func test_정상상태_휴지통단일삭제시_리포지토리의단일삭제메서드를호출한다() async throws {
        // Given
        let item: WasteBasketItem = .folder(id: UUID())
        let repository = MockWasteBasketRepository()
        await repository.setDeleteResult(.success(()))
        await repository.expectDelete(item: item, callCount: 1)

        let useCase = DefaultDeleteWasteBasketUseCase(repository: repository)

        // When
        _ = try await useCase.execute(method: .single(item: item))

        // Then
        await repository.verify()
    }
}

// MARK: - 에러 케이스

extension DeleteWasteBasketUseCaseTest {
    func test_리포지토리비우기실패상태_휴지통비우기시_deleteFailed에러를던진다() async {
        // Given
        let method = DeleteWasteBasketMethod.all
        let repository = MockWasteBasketRepository()
        await repository.setDeleteResult(.failure(.deleteFailed(method)))
        await repository.expectAllClear(callCount: 1)

        let useCase = DefaultDeleteWasteBasketUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(method: method)
            XCTFail("에러가 발생해야 합니다.")
        } catch UseCaseError.deleteFailed(let failedMethod) {
            XCTAssertEqual(failedMethod, method)
            await repository.verify()
        } catch {
            XCTFail("Expected .deleteFailed, got \(error)")
        }
    }

    func test_리포지토리단일삭제실패상태_휴지통단일삭제시_deleteFailed에러를던진다() async {
        // Given
        let item = WasteBasketItem.folder(id: UUID())
        let method = DeleteWasteBasketMethod.single(item: item)
        let repository = MockWasteBasketRepository()
        await repository.setDeleteResult(.failure(.deleteFailed(method)))
        await repository.expectDelete(callCount: 1)

        let useCase = DefaultDeleteWasteBasketUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(method: method)
            XCTFail("에러가 발생해야 합니다.")
        } catch UseCaseError.deleteFailed(let failedMethod) {
            XCTAssertEqual(failedMethod, method)
            await repository.verify()
        } catch {
            XCTFail("Expected .deleteFailed, got \(error)")
        }
    }

    func test_리포지토리다중삭제실패상태_휴지통다중삭제시_deleteFailed에러를던진다() async {
        // Given
        let items: [WasteBasketItem] = [.folder(id: UUID())]
        let method = DeleteWasteBasketMethod.multiple(items: items)
        let repository = MockWasteBasketRepository()
        await repository.setDeleteResult(.failure(.deleteFailed(method)))
        await repository.expectDeleteAll(callCount: 1)

        let useCase = DefaultDeleteWasteBasketUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(method: method)
            XCTFail("에러가 발생해야 합니다.")
        } catch UseCaseError.deleteFailed(let failedMethod) {
            XCTAssertEqual(failedMethod, method)
            await repository.verify()
        } catch {
            XCTFail("Expected .deleteFailed, got \(error)")
        }
    }

    func test_리포지토리알수없는에러상태_휴지통삭제시_unknown에러를던진다() async {
        // Given
        struct Dummy: Error {}
        let dummyError = Dummy()
        let repository = MockWasteBasketRepository()
        await repository.setDeleteResult(.failure(.unknown(dummyError)))
        await repository.expectAllClear(callCount: 1)

        let useCase = DefaultDeleteWasteBasketUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(method: .all)
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

extension DeleteWasteBasketUseCaseTest {
    func test_작업취소상태_휴지통삭제시_cancelled에러를던진다() async {
        // Given
        let repository = MockWasteBasketRepository()
        await repository.setDeleteResult(.failure(.cancelled))
        await repository.expectAllClear(callCount: 1)

        let useCase = DefaultDeleteWasteBasketUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(method: .all)
            XCTFail("에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            await repository.verify()
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }

    func test_태스크이미취소상태_휴지통삭제시_즉시cancelled에러를던진다() async {
        // Given
        let repository = MockWasteBasketRepository()
        await repository.setDeleteResult(.success(()))
        await repository.expectAllClear(callCount: 0)

        let useCase = DefaultDeleteWasteBasketUseCase(repository: repository)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await useCase.execute(method: .all)
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
