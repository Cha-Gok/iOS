@testable import Domain
import Core
import XCTest

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

// MARK: - 성공 케이스

extension CheckSTTPermissionUseCaseTest {
    func test_STT권한허용상태_권한조회시_authorized를반환한다() async throws {
        // Given
        await repository.setResult(.success(.authorized))
        await repository.expectCheckSTTPermission(callCount: 1)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result, .authorized)
        await repository.verify()
    }

    func test_STT권한거부상태_권한조회시_denied를반환한다() async throws {
        // Given
        await repository.setResult(.success(.denied))
        await repository.expectCheckSTTPermission(callCount: 1)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result, .denied)
        await repository.verify()
    }

    func test_STT권한미결정상태_권한조회시_notDetermined를반환한다() async throws {
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

// MARK: - 에러 케이스

extension CheckSTTPermissionUseCaseTest {
    func test_리포지토리에러발생상태_권한조회시_unknown에러를던진다() async {
        // Given
        struct DummyError: Error {}
        let expectedError = DummyError()
        await repository.setResult(.failure(.unknown(expectedError)))
        await repository.expectCheckSTTPermission(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("CheckSTTPermissionUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let error) = error else {
                return XCTFail("예상한 에러는 CheckSTTPermissionUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
            XCTAssertTrue(error is DummyError)
        }

        await repository.verify()
    }

    func test_태스크취소상태_권한조회시_cancelled에러를던진다() async throws {
        // Given
        await repository.expectCheckSTTPermission(callCount: 0)

        let sut = try XCTUnwrap(sut)
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
                return XCTFail("예상한 에러는 CheckSTTPermissionUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }

        await repository.verify()
    }
}
