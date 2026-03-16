import Core
import XCTest

@testable import Domain

final class CheckSTTPermissionUseCaseTest: XCTestCase {

    private var repository: MockSTTPermissionRepository!
    private var sut: DefaultCheckSTTPermissionUseCase!

    override func setUp() {
        super.setUp()
        repository = MockSTTPermissionRepository()
        sut = DefaultCheckSTTPermissionUseCase(repository: repository)
    }

    override func tearDown() {
        repository = nil
        sut = nil
        super.tearDown()
    }
}

// MARK: - 성공
extension CheckSTTPermissionUseCaseTest {

    func test_execute_STT권한이허용된경우_authorized상태를반환한다() async throws {
        // Given
        await repository.setResult(.success(.authorized))
        await repository.expectCheckSTTPermission(callCount: 1)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result, .authorized)
        await repository.verify()
    }

    func test_execute_STT권한이거부된경우_denied상태를반환한다() async throws {
        // Given
        await repository.setResult(.success(.denied))
        await repository.expectCheckSTTPermission(callCount: 1)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result, .denied)
        await repository.verify()
    }

    func test_execute_STT권한이결정되지않은경우_notDetermined상태를반환한다() async throws {
        // Given
        await repository.setResult(.success(.notDetermined))
        await repository.expectCheckSTTPermission(callCount: 1)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result, .notDetermined)
        await repository.verify()
    }
}

// MARK: - 실패
extension CheckSTTPermissionUseCaseTest {

    func test_execute_리포지토리에서에러가발생한경우_UseCase에러로변환하여던진다() async {
        // Given
        struct DummyError: Error {}
        let expectedError = DummyError()
        await repository.setResult(.failure(.unknown(expectedError)))
        await repository.expectCheckSTTPermission(callCount: 1)

        // When
        do {
            _ = try await sut.execute()
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let error) = error else {
                return XCTFail("expected CheckSTTPermissionUseCaseError, got \(error)")
            }
            XCTAssertTrue(error is DummyError)
        }

        // Then
        await repository.verify()
    }
}

// MARK: - Task 취소
extension CheckSTTPermissionUseCaseTest {

    func test_execute_실행전에태스크가취소되면_리포지토리호출없이cancelled에러를던진다() async {
        guard let sut else { return XCTFail("sut은 반드시 설정되어야 합니다.") }
        // Given
        await repository.expectCheckSTTPermission(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.execute()
        }

        // When
        do {
            _ = try await task.value
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? CheckSTTPermissionUseCaseError else {
                return XCTFail("expected .cancelled, got \(error)")
            }
        }

        // Then
        await repository.verify()
    }

}
