@testable import Domain
import Core
import XCTest

final class CheckMicrophonePermissionUseCaseTest: XCTestCase {
    private var authorityRepository: MockMicrophonePermissionRepository!
    private var sut: DefaultCheckMicrophonePermissionUseCase!

    override func setUp() {
        super.setUp()
        authorityRepository = MockMicrophonePermissionRepository()
        sut = DefaultCheckMicrophonePermissionUseCase(repository: authorityRepository)
    }

    override func tearDown() {
        authorityRepository = nil
        sut = nil
        super.tearDown()
    }
}

// MARK: - 성공 케이스

extension CheckMicrophonePermissionUseCaseTest {
    func test_마이크권한허용상태_권한조회시_authorized를반환한다() async throws {
        // Given
        await authorityRepository.setCheckResult(.success(.authorized))
        await authorityRepository.expectCheckMicrophonePermission(callCount: 1)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result, .authorized)
        await authorityRepository.verify()
    }

    func test_마이크권한거부상태_권한조회시_denied를반환한다() async throws {
        // Given
        await authorityRepository.setCheckResult(.success(.denied))
        await authorityRepository.expectCheckMicrophonePermission(callCount: 1)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result, .denied)
        await authorityRepository.verify()
    }

    func test_마이크권한미결정상태_권한조회시_notDetermined를반환한다() async throws {
        // Given
        await authorityRepository.setCheckResult(.success(.notDetermined))
        await authorityRepository.expectCheckMicrophonePermission(callCount: 1)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result, .notDetermined)
        await authorityRepository.verify()
    }
}

// MARK: - 에러 케이스

extension CheckMicrophonePermissionUseCaseTest {
    func test_리포지토리에러발생상태_권한조회시_unknown에러를던진다() async {
        // Given
        struct DummyError: Error {}
        let expectedError = DummyError()
        await authorityRepository.setCheckResult(.failure(.unknown(expectedError)))
        await authorityRepository.expectCheckMicrophonePermission(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("CheckMicrophonePermissionUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard
                case .unknown(let underlyingError) = error
            else {
                return XCTFail(
                    "예상한 에러는 CheckMicrophonePermissionUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
            XCTAssertTrue(underlyingError is DummyError)
        }

        await authorityRepository.verify()
    }

    func test_태스크취소상태_권한조회시_cancelled에러를던진다() async throws {
        guard let sut else {
            return XCTFail("sut가 초기화되지 않았습니다.")
        }
        // Given
        await authorityRepository.expectCheckMicrophonePermission(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.execute()
        }

        // When & Then
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

        await authorityRepository.verify()
    }
}
