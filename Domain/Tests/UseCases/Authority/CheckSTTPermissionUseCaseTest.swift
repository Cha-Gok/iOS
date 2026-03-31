@testable import Domain
import Core
import XCTest

final class CheckSTTPermissionUseCaseTest: XCTestCase {}

// MARK: - 성공 케이스

extension CheckSTTPermissionUseCaseTest {
    func test_STT권한허용상태_권한조회시_authorized를반환한다() async throws {
        let authorityRepository = MockSTTRepository()
        let sut = DefaultCheckSTTPermissionUseCase(repository: authorityRepository)

        // Given
        await authorityRepository.setCheckResult(.success(.authorized))
        await authorityRepository.expectCheckSTTPermission(callCount: 1)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result, .authorized)
        await authorityRepository.verify()
    }

    func test_STT권한거부상태_권한조회시_denied를반환한다() async throws {
        let authorityRepository = MockSTTRepository()
        let sut = DefaultCheckSTTPermissionUseCase(repository: authorityRepository)

        // Given
        await authorityRepository.setCheckResult(.success(.denied))
        await authorityRepository.expectCheckSTTPermission(callCount: 1)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result, .denied)
        await authorityRepository.verify()
    }

    func test_STT권한미결정상태_권한조회시_notDetermined를반환한다() async throws {
        let authorityRepository = MockSTTRepository()
        let sut = DefaultCheckSTTPermissionUseCase(repository: authorityRepository)

        // Given
        await authorityRepository.setCheckResult(.success(.notDetermined))
        await authorityRepository.expectCheckSTTPermission(callCount: 1)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result, .notDetermined)
        await authorityRepository.verify()
    }
}

// MARK: - 에러 케이스

extension CheckSTTPermissionUseCaseTest {
    func test_리포지토리에러발생상태_권한조회시_unknown에러를던진다() async {
        let authorityRepository = MockSTTRepository()
        let sut = DefaultCheckSTTPermissionUseCase(repository: authorityRepository)

        // Given
        struct DummyError: Error {}
        let expectedError = DummyError()
        await authorityRepository.setCheckResult(.failure(.unknown(expectedError)))
        await authorityRepository.expectCheckSTTPermission(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("CheckSTTPermissionUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let underlyingError) = error
            else {
                return XCTFail(
                    "예상한 에러는 CheckSTTPermissionUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
            XCTAssertTrue(underlyingError is DummyError)
        }

        await authorityRepository.verify()
    }

    func test_태스크취소상태_권한조회시_cancelled에러를던진다() async {
        let authorityRepository = MockSTTRepository()
        let sut = DefaultCheckSTTPermissionUseCase(repository: authorityRepository)

        // Given
        await authorityRepository.expectCheckSTTPermission(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.execute()
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("CheckSTTPermissionUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? CheckSTTPermissionUseCaseError else {
                return XCTFail(
                    "예상한 에러는 CheckSTTPermissionUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await authorityRepository.verify()
    }
}
