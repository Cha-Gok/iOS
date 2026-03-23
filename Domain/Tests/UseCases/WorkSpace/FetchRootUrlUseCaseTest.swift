@testable import Domain
import Core
import XCTest

final class FetchRootUrlUseCaseTest: XCTestCase {}

// MARK: - 성공 케이스

extension FetchRootUrlUseCaseTest {
    func test_정상상태_루트URL조회시_기대하는URL을반환한다() async throws {
        let repository = MockWorkSpaceRepository()
        let sut = DefaultFetchRootUrlUseCase(repository: repository)

        // Given
        let expectedURL = URL.applicationSupportDirectory
        await repository.setRootURLResult(.success(expectedURL))
        await repository.expectFetchRootURL(callCount: 1)

        // When
        let url = try await sut.execute()

        // Then
        XCTAssertEqual(url, expectedURL)
        await repository.verify()
    }
}

// MARK: - 에러 케이스

extension FetchRootUrlUseCaseTest {
    func test_알수없는에러발생상태_루트URL조회시_unknown에러를던진다() async {
        let repository = MockWorkSpaceRepository()
        let sut = DefaultFetchRootUrlUseCase(repository: repository)

        // Given
        struct DummyError: Error {}
        await repository.setRootURLResult(.failure(.unknown(DummyError())))
        await repository.expectFetchRootURL(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("FetchRootUrlUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let repoError) = error else {
                return XCTFail(
                    "예상한 에러는 FetchRootUrlUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
            XCTAssertTrue(repoError is DummyError)
        }
        await repository.verify()
    }
}

// MARK: - 취소 케이스

extension FetchRootUrlUseCaseTest {
    func test_조회중취소상태_루트URL조회시_cancelled에러를던진다() async {
        let repository = MockWorkSpaceRepository()
        let sut = DefaultFetchRootUrlUseCase(repository: repository)

        // Given
        await repository.setRootURLResult(.failure(.cancelled))
        await repository.expectFetchRootURL(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("FetchRootUrlUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error else {
                return XCTFail(
                    "예상한 에러는 FetchRootUrlUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
        await repository.verify()
    }

    func test_태스크이미취소상태_루트URL조회시_즉시cancelled에러를던진다() async {
        let repository = MockWorkSpaceRepository()
        let sut = DefaultFetchRootUrlUseCase(repository: repository)

        // Given
        let testURL: URL = .applicationSupportDirectory
        await repository.setRootURLResult(.success(testURL))
        await repository.expectFetchRootURL(callCount: 0)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.execute()
        }

        do {
            _ = try await task.value
            XCTFail("FetchRootUrlUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? FetchRootUrlUseCaseError else {
                return XCTFail(
                    "예상한 에러는 FetchRootUrlUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
        await repository.verify()
    }
}
