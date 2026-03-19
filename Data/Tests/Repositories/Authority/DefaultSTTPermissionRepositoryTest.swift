@testable import Data
import Domain
import XCTest

final class DefaultSTTPermissionRepositoryTest: XCTestCase {}

// MARK: - 권한 확인 성공 케이스

extension DefaultSTTPermissionRepositoryTest {
    func test_STT권한허용상태_권한확인시_authorized를반환한다() async throws {
        let service = MockSTTPermissionService()
        let sut = DefaultSTTPermissionRepository(service: service)

        // Given
        await service.setCheckResult(.authorized)
        await service.expectCheck(callCount: 1)

        // When
        let result = try await sut.checkSTTPermission()

        // Then
        XCTAssertEqual(result, .authorized)
        await service.verify()
    }

    func test_STT권한거부상태_권한확인시_denied를반환한다() async throws {
        let service = MockSTTPermissionService()
        let sut = DefaultSTTPermissionRepository(service: service)

        // Given
        await service.setCheckResult(.denied)
        await service.expectCheck(callCount: 1)

        // When
        let result = try await sut.checkSTTPermission()

        // Then
        XCTAssertEqual(result, .denied)
        await service.verify()
    }

    func test_STT권한미결정상태_권한확인시_notDetermined를반환한다() async throws {
        let service = MockSTTPermissionService()
        let sut = DefaultSTTPermissionRepository(service: service)

        // Given
        await service.setCheckResult(.notDetermined)
        await service.expectCheck(callCount: 1)

        // When
        let result = try await sut.checkSTTPermission()

        // Then
        XCTAssertEqual(result, .notDetermined)
        await service.verify()
    }
}

// MARK: - 권한 확인 취소 케이스

extension DefaultSTTPermissionRepositoryTest {
    func test_태스크취소상태_권한확인시_cancelled에러를던진다() async throws {
        let service = MockSTTPermissionService()
        let sut = DefaultSTTPermissionRepository(service: service)

        // Given
        await service.expectCheck(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.checkSTTPermission()
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("STTPermissionRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? STTPermissionRepositoryError else {
                return XCTFail(
                    "예상한 에러는 STTPermissionRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await service.verify()
    }
}

// MARK: - 권한 요청 성공 케이스

extension DefaultSTTPermissionRepositoryTest {
    func test_STT권한허용상태_권한요청시_authorized를반환한다() async throws {
        let service = MockSTTPermissionService()
        let sut = DefaultSTTPermissionRepository(service: service)

        // Given
        await service.setRequestResult(.authorized)
        await service.expectRequest(callCount: 1)

        // When
        let result = try await sut.requestSTTPermission()

        // Then
        XCTAssertEqual(result, .authorized)
        await service.verify()
    }

    func test_STT권한거부상태_권한요청시_denied를반환한다() async throws {
        let service = MockSTTPermissionService()
        let sut = DefaultSTTPermissionRepository(service: service)

        // Given
        await service.setRequestResult(.denied)
        await service.expectRequest(callCount: 1)

        // When
        let result = try await sut.requestSTTPermission()

        // Then
        XCTAssertEqual(result, .denied)
        await service.verify()
    }
}

// MARK: - 권한 요청 취소 케이스

extension DefaultSTTPermissionRepositoryTest {
    func test_태스크취소상태_권한요청시_cancelled에러를던진다() async throws {
        let service = MockSTTPermissionService()
        let sut = DefaultSTTPermissionRepository(service: service)

        // Given
        await service.expectRequest(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.requestSTTPermission()
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("STTPermissionRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? STTPermissionRepositoryError else {
                return XCTFail(
                    "예상한 에러는 STTPermissionRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await service.verify()
    }
}
