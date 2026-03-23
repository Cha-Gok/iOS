@testable import Domain
import Core
import XCTest

final class RequestMicrophonePermissionUseCaseTest: XCTestCase {}

// MARK: - 성공 케이스

extension RequestMicrophonePermissionUseCaseTest {
    func test_마이크권한미결정상태_권한요청시_authorized를반환한다() async throws {
        let authorityRepository = MockMicrophonePermissionRepository()
        let sut = DefaultRequestMicrophonePermissionUseCase(repository: authorityRepository)

        // Given
        await authorityRepository.setRequestResult(.success(.authorized))
        await authorityRepository.expectRequestMicrophonePermission(callCount: 1)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result, .authorized)
        await authorityRepository.verify()
    }

    func test_마이크권한이미거부상태_권한요청시_denied를반환한다() async throws {
        let authorityRepository = MockMicrophonePermissionRepository()
        let sut = DefaultRequestMicrophonePermissionUseCase(repository: authorityRepository)

        // Given
        await authorityRepository.setRequestResult(.success(.denied))
        await authorityRepository.expectRequestMicrophonePermission(callCount: 1)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result, .denied)
        await authorityRepository.verify()
    }
}

// MARK: - 에러 케이스

extension RequestMicrophonePermissionUseCaseTest {
    func test_리포지토리에러발생상태_권한요청시_unknown에러를던진다() async {
        let authorityRepository = MockMicrophonePermissionRepository()
        let sut = DefaultRequestMicrophonePermissionUseCase(repository: authorityRepository)

        // Given
        struct DummyError: Error {}
        let expectedError = DummyError()
        await authorityRepository.setRequestResult(.failure(.unknown(expectedError)))
        await authorityRepository.expectRequestMicrophonePermission(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("RequestMicrophonePermissionUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard
                case .unknown(let underlyingError) = error
            else {
                return XCTFail(
                    "예상한 에러는 RequestMicrophonePermissionUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
            XCTAssertTrue(underlyingError is DummyError)
        }

        await authorityRepository.verify()
    }
}

// MARK: - 취소 케이스

extension RequestMicrophonePermissionUseCaseTest {
    func test_태스크취소상태_권한요청시_cancelled에러를던진다() async {
        let authorityRepository = MockMicrophonePermissionRepository()
        let sut = DefaultRequestMicrophonePermissionUseCase(repository: authorityRepository)

        // Given
        await authorityRepository.expectRequestMicrophonePermission(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.execute()
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("RequestMicrophonePermissionUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? RequestMicrophonePermissionUseCaseError else {
                return XCTFail(
                    "예상한 에러는 RequestMicrophonePermissionUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await authorityRepository.verify()
    }
}
