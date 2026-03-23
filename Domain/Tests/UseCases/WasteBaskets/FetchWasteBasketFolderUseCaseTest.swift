@testable import Domain
import Core
import XCTest

final class FetchWasteBasketFolderUseCaseTest: XCTestCase {}

// MARK: - 성공 케이스

extension FetchWasteBasketFolderUseCaseTest {
    func test_정상상태_휴지통항목조회시_전체항목목록을반환한다() async throws {
        let wasteBasketRepository = MockWasteBasketRepository()
        let sut = DefaultFetchWasteBasketFolderUseCase(repository: wasteBasketRepository)

        // Given
        let expectedItems: [WasteBasketItem] = [
            .folder(id: UUID()),
            .voiceNote(id: UUID())
        ]
        await wasteBasketRepository.setFetchAllResult(.success(expectedItems))
        await wasteBasketRepository.expectFetchAll(callCount: 1)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result, expectedItems)
        await wasteBasketRepository.verify()
    }

    func test_데이터미존재상태_휴지통항목조회시_빈배열을반환한다() async throws {
        let wasteBasketRepository = MockWasteBasketRepository()
        let sut = DefaultFetchWasteBasketFolderUseCase(repository: wasteBasketRepository)

        // Given
        await wasteBasketRepository.setFetchAllResult(.success([]))
        await wasteBasketRepository.expectFetchAll(callCount: 1)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertTrue(result.isEmpty)
        await wasteBasketRepository.verify()
    }
}

// MARK: - 에러 케이스

extension FetchWasteBasketFolderUseCaseTest {
    func test_리포지토리조회실패상태_휴지통항목조회시_fetchFailed에러를던진다() async {
        let wasteBasketRepository = MockWasteBasketRepository()
        let sut = DefaultFetchWasteBasketFolderUseCase(repository: wasteBasketRepository)

        // Given
        await wasteBasketRepository.setFetchAllResult(.failure(.fetchFailed))
        await wasteBasketRepository.expectFetchAll(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("FetchWasteBasketFolderUseCaseError.fetchFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .fetchFailed = error else {
                return XCTFail(
                    "예상한 에러는 FetchWasteBasketFolderUseCaseError.fetchFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
        await wasteBasketRepository.verify()
    }

    func test_리포지토리알수없는에러상태_휴지통항목조회시_unknown에러를던진다() async {
        let wasteBasketRepository = MockWasteBasketRepository()
        let sut = DefaultFetchWasteBasketFolderUseCase(repository: wasteBasketRepository)

        // Given
        struct DummyError: Error {}
        let expectedError = DummyError()
        await wasteBasketRepository.setFetchAllResult(.failure(.unknown(expectedError)))
        await wasteBasketRepository.expectFetchAll(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("FetchWasteBasketFolderUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let underlyingError) = error
            else {
                return XCTFail(
                    "예상한 에러는 FetchWasteBasketFolderUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
            XCTAssertTrue(underlyingError is DummyError)
        }
        await wasteBasketRepository.verify()
    }
}

// MARK: - 취소 케이스

extension FetchWasteBasketFolderUseCaseTest {
    func test_작업취소상태_휴지통항목조회시_cancelled에러를던진다() async {
        let wasteBasketRepository = MockWasteBasketRepository()
        let sut = DefaultFetchWasteBasketFolderUseCase(repository: wasteBasketRepository)

        // Given
        await wasteBasketRepository.setFetchAllResult(.failure(.cancelled))
        await wasteBasketRepository.expectFetchAll(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("FetchWasteBasketFolderUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error else {
                return XCTFail(
                    "예상한 에러는 FetchWasteBasketFolderUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
        await wasteBasketRepository.verify()
    }

    func test_태스크이미취소상태_휴지통항목조회시_즉시cancelled에러를던진다() async {
        let wasteBasketRepository = MockWasteBasketRepository()
        let sut = DefaultFetchWasteBasketFolderUseCase(repository: wasteBasketRepository)

        // Given
        await wasteBasketRepository.setFetchAllResult(.success([]))
        await wasteBasketRepository.expectFetchAll(callCount: 0)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await sut.execute()
        }

        do {
            _ = try await task.value
            XCTFail("FetchWasteBasketFolderUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? FetchWasteBasketFolderUseCaseError else {
                return XCTFail(
                    "예상한 에러는 FetchWasteBasketFolderUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
        await wasteBasketRepository.verify()
    }
}
