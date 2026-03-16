import XCTest
@testable import Domain

final class DeleteWasteBasketUseCaseTest: XCTestCase {
    typealias UseCaseError = DeleteWasteBasketUseCaseError
}

// MARK: - Success Cases

extension DeleteWasteBasketUseCaseTest {

    func test_휴지통_삭제_전체삭제_성공_리포지토리를호출한다() async throws {
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

    func test_휴지통_삭제_다중삭제_성공_리포지토리를호출한다() async throws {
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

    func test_휴지통_삭제_단일삭제_성공_리포지토리를호출한다() async throws {
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

// MARK: - Error Mapping Cases

extension DeleteWasteBasketUseCaseTest {

    func test_휴지통_삭제_리포지토리삭제실패시_deleteFailed에러를던진다() async {
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

    func test_휴지통_삭제_리포지토리단일삭제실패시_deleteFailed에러를던진다() async {
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

    func test_휴지통_삭제_리포지토리다중삭제실패시_deleteFailed에러를던진다() async {
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

    func test_휴지통_삭제_리포지토리알수없는에러시_unknown에러를던진다() async {
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

    func test_휴지통_삭제_리포지토리취소시_cancelled에러를던진다() async {
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
}

// MARK: - Cancellation Case

extension DeleteWasteBasketUseCaseTest {

    func test_휴지통_삭제_작업전_즉시cancelled에러를던진다() async {
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
