@testable import Domain
import Core
import XCTest

final class CheckMicrophonePermissionUseCaseTest: XCTestCase {
    private var repository: MockMicrophonePermissionRepository!
    private var sut: DefaultCheckMicrophonePermissionUseCase!

    override func setUp() {
        super.setUp()
        repository = MockMicrophonePermissionRepository()
        sut = DefaultCheckMicrophonePermissionUseCase(repository: repository)
    }

    override func tearDown() {
        repository = nil
        sut = nil
        super.tearDown()
    }
}

// MARK: - 성공

extension CheckMicrophonePermissionUseCaseTest {
    func test_execute_마이크권한이허용된경우_authorized상태를반환한다() async throws {
        // Given
        await repository.setResult(.success(.authorized))
        await repository.expectCheckMicrophonePermission(callCount: 1)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result, .authorized)
        await repository.verify()
    }

    func test_execute_마이크권한이거부된경우_denied상태를반환한다() async throws {
        // Given
        await repository.setResult(.success(.denied))
        await repository.expectCheckMicrophonePermission(callCount: 1)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result, .denied)
        await repository.verify()
    }

    func test_execute_마이크권한이결정되지않은경우_notDetermined상태를반환한다() async throws {
        // Given
        await repository.setResult(.success(.notDetermined))
        await repository.expectCheckMicrophonePermission(callCount: 1)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result, .notDetermined)
        await repository.verify()
    }
}

// MARK: - 실패 / 에러 매핑

extension CheckMicrophonePermissionUseCaseTest {
    func test_execute_리포지토리에서에러가발생한경우_UseCase에러로변환하여던진다() async {
        // Given
        struct DummyError: Error {}
        let expectedError = DummyError()
        await repository.setResult(.failure(.unknown(expectedError)))
        await repository.expectCheckMicrophonePermission(callCount: 1)

        // When
        do {
            _ = try await sut.execute()
            XCTFail("CheckMicrophonePermissionUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let underlyingError) = error else {
                return XCTFail(
                    "예상한 에러는 CheckMicrophonePermissionUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
            XCTAssertTrue(underlyingError is DummyError, "내부 에러 타입은 DummyError 여야 합니다.")
        }

        // Then
        await repository.verify()
    }
}

// MARK: - Task 취소

extension CheckMicrophonePermissionUseCaseTest {
    func test_execute_실행전에태스크가취소되면_리포지토리호출없이cancelled에러를던진다() async {
        guard let sut else { return XCTFail("sut은 반드시 설정되어야 합니다.") }
        // Given
        await repository.expectCheckMicrophonePermission(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.execute()
        }

        // When
        do {
            _ = try await task.value
            XCTFail("CheckMicrophonePermissionUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? CheckMicrophonePermissionUseCaseError else {
                return XCTFail(
                    "예상한 에러는 CheckMicrophonePermissionUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        // Then
        await repository.verify()
    }
}
