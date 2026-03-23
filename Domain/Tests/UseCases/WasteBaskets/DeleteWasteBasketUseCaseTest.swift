@testable import Domain
import Core
import XCTest

final class DeleteWasteBasketUseCaseTest: XCTestCase {}

// MARK: - 성공 케이스

extension DeleteWasteBasketUseCaseTest {
    func test_정상상태_휴지통비우기시_리포지토리의비우기메서드를호출한다() async throws {
        let wasteBasketRepository = MockWasteBasketRepository()
        let sut = DefaultDeleteWasteBasketUseCase(repository: wasteBasketRepository)

        // Given
        await wasteBasketRepository.setDeleteResult(.success(()))
        await wasteBasketRepository.expectAllClear(callCount: 1)

        // When
        _ = try await sut.execute(method: .all)

        // Then
        await wasteBasketRepository.verify()
    }

    func test_정상상태_휴지통다중삭제시_리포지토리의다중삭제메서드를호출한다() async throws {
        let wasteBasketRepository = MockWasteBasketRepository()
        let sut = DefaultDeleteWasteBasketUseCase(repository: wasteBasketRepository)

        // Given
        let items: [WasteBasketItem] = [
            .folder(id: UUID()),
            .voiceNote(id: UUID())
        ]
        await wasteBasketRepository.setDeleteResult(.success(()))
        await wasteBasketRepository.expectDeleteAll(items: items, callCount: 1)

        // When
        _ = try await sut.execute(method: .multiple(items: items))

        // Then
        await wasteBasketRepository.verify()
    }

    func test_정상상태_휴지통단일삭제시_리포지토리의단일삭제메서드를호출한다() async throws {
        let wasteBasketRepository = MockWasteBasketRepository()
        let sut = DefaultDeleteWasteBasketUseCase(repository: wasteBasketRepository)

        // Given
        let item: WasteBasketItem = .folder(id: UUID())
        await wasteBasketRepository.setDeleteResult(.success(()))
        await wasteBasketRepository.expectDelete(item: item, callCount: 1)

        // When
        _ = try await sut.execute(method: .single(item: item))

        // Then
        await wasteBasketRepository.verify()
    }
}

// MARK: - 에러 케이스

extension DeleteWasteBasketUseCaseTest {
    func test_리포지토리비우기실패상태_휴지통비우기시_deleteFailed에러를던진다() async {
        let wasteBasketRepository = MockWasteBasketRepository()
        let sut = DefaultDeleteWasteBasketUseCase(repository: wasteBasketRepository)

        // Given
        let method = DeleteWasteBasketMethod.all
        await wasteBasketRepository.setDeleteResult(.failure(.deleteFailed(method)))
        await wasteBasketRepository.expectAllClear(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute(method: method)
            XCTFail("DeleteWasteBasketUseCaseError.deleteFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .deleteFailed(let failedMethod) = error else {
                return XCTFail("예상한 에러는 DeleteWasteBasketUseCaseError.deleteFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
            XCTAssertEqual(failedMethod, method)
        }
        await wasteBasketRepository.verify()
    }

    func test_리포지토리단일삭제실패상태_휴지통단일삭제시_deleteFailed에러를던진다() async {
        let wasteBasketRepository = MockWasteBasketRepository()
        let sut = DefaultDeleteWasteBasketUseCase(repository: wasteBasketRepository)

        // Given
        let item = WasteBasketItem.folder(id: UUID())
        let method = DeleteWasteBasketMethod.single(item: item)
        await wasteBasketRepository.setDeleteResult(.failure(.deleteFailed(method)))
        await wasteBasketRepository.expectDelete(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute(method: method)
            XCTFail("DeleteWasteBasketUseCaseError.deleteFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .deleteFailed(let failedMethod) = error else {
                return XCTFail("예상한 에러는 DeleteWasteBasketUseCaseError.deleteFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
            XCTAssertEqual(failedMethod, method)
        }
        await wasteBasketRepository.verify()
    }

    func test_리포지토리다중삭제실패상태_휴지통다중삭제시_deleteFailed에러를던진다() async {
        let wasteBasketRepository = MockWasteBasketRepository()
        let sut = DefaultDeleteWasteBasketUseCase(repository: wasteBasketRepository)

        // Given
        let items: [WasteBasketItem] = [.folder(id: UUID())]
        let method = DeleteWasteBasketMethod.multiple(items: items)
        await wasteBasketRepository.setDeleteResult(.failure(.deleteFailed(method)))
        await wasteBasketRepository.expectDeleteAll(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute(method: method)
            XCTFail("DeleteWasteBasketUseCaseError.deleteFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .deleteFailed(let failedMethod) = error else {
                return XCTFail("예상한 에러는 DeleteWasteBasketUseCaseError.deleteFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
            XCTAssertEqual(failedMethod, method)
        }
        await wasteBasketRepository.verify()
    }

    func test_리포지토리알수없는에러상태_휴지통삭제시_unknown에러를던진다() async {
        let wasteBasketRepository = MockWasteBasketRepository()
        let sut = DefaultDeleteWasteBasketUseCase(repository: wasteBasketRepository)

        // Given
        struct DummyError: Error {}
        let expectedError = DummyError()
        await wasteBasketRepository.setDeleteResult(.failure(.unknown(expectedError)))
        await wasteBasketRepository.expectAllClear(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute(method: .all)
            XCTFail("DeleteWasteBasketUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let underlyingError) = error else {
                return XCTFail("예상한 에러는 DeleteWasteBasketUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
            XCTAssertTrue(underlyingError is DummyError)
        }
        await wasteBasketRepository.verify()
    }
}

// MARK: - 취소 케이스

extension DeleteWasteBasketUseCaseTest {
    func test_작업취소상태_휴지통삭제시_cancelled에러를던진다() async {
        let wasteBasketRepository = MockWasteBasketRepository()
        let sut = DefaultDeleteWasteBasketUseCase(repository: wasteBasketRepository)

        // Given
        await wasteBasketRepository.setDeleteResult(.failure(.cancelled))
        await wasteBasketRepository.expectAllClear(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute(method: .all)
            XCTFail("DeleteWasteBasketUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error else {
                return XCTFail("예상한 에러는 DeleteWasteBasketUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await wasteBasketRepository.verify()
    }

    func test_태스크이미취소상태_휴지통삭제시_즉시cancelled에러를던진다() async {
        let wasteBasketRepository = MockWasteBasketRepository()
        let sut = DefaultDeleteWasteBasketUseCase(repository: wasteBasketRepository)

        // Given
        await wasteBasketRepository.setDeleteResult(.success(()))
        await wasteBasketRepository.expectAllClear(callCount: 0)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await sut.execute(method: .all)
        }

        do {
            _ = try await task.value
            XCTFail("DeleteWasteBasketUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? DeleteWasteBasketUseCaseError else {
                return XCTFail("예상한 에러는 DeleteWasteBasketUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await wasteBasketRepository.verify()
    }
}
