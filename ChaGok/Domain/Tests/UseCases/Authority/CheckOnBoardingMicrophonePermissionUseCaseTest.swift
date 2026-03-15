import XCTest
@testable import Domain

final class CheckOnBoardingMicrophonePermissionUseCaseTest: XCTestCase {
    typealias UseCaseError = CheckOnBoardingMicrophonePermissionUseCaseError
}

// MARK: - Success Cases

extension CheckOnBoardingMicrophonePermissionUseCaseTest {

    func test_execute_마이크권한조회에성공하여_authorized를반환한다() async throws {
        // Given
        let repository = MockVoiceRecordPermissionRepository()
        await repository.setResult(.success(()))
        await repository.expectCheckRecordingPermission(callCount: 1)

        let useCase = DefaultCheckOnBoardingMicrophonePermissionUseCase(repository: repository)

        // When
        let status = try await useCase.execute()

        // Then
        XCTAssertEqual(status, .authorized)
        await repository.verify()
    }

    func test_execute_마이크권한이거부상태라면_에러를던지지않고_denied를반환한다() async throws {
        // Given
        let repository = MockVoiceRecordPermissionRepository()
        await repository.setResult(.failure(.permissionDenied))
        await repository.expectCheckRecordingPermission(callCount: 1)

        let useCase = DefaultCheckOnBoardingMicrophonePermissionUseCase(repository: repository)

        // When
        let status = try await useCase.execute()

        // Then
        XCTAssertEqual(status, .denied)
        await repository.verify()
    }
}

// MARK: - Error Cases

extension CheckOnBoardingMicrophonePermissionUseCaseTest {

    func test_execute_마이크권한조회중알수없는에러가발생하면_unknown에러를던진다() async {
        // Given
        struct Dummy: Error {}
        let dummyError = Dummy()
        let repository = MockVoiceRecordPermissionRepository()
        await repository.setResult(.failure(.unknown(dummyError)))
        await repository.expectCheckRecordingPermission(callCount: 1)

        let useCase = DefaultCheckOnBoardingMicrophonePermissionUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("알 수 없는 에러 발생 시 .unknown으로 래핑되어야 합니다.")
        } catch {
            switch error {
            case .unknown(let repoError):
                // RepoError.unknown 내부의 Dummy 에러가 유지되어야 함
                XCTAssertTrue(repoError is Dummy)
                await repository.verify()
            default:
                XCTFail("Expected .unknown, got \(error)")
            }
        }
    }
}

// MARK: - Error Cases ( Cancelled )

extension CheckOnBoardingMicrophonePermissionUseCaseTest {

    func test_execute_마이크권한조회중취소되면_cancelled에러를던진다() async {
        // Given
        let repository = MockVoiceRecordPermissionRepository()
        await repository.setResult(.failure(.cancelled))
        await repository.expectCheckRecordingPermission(callCount: 1)

        let useCase = DefaultCheckOnBoardingMicrophonePermissionUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("작업 취소의 경우 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
            await repository.verify()
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }

    func test_execute_마이크권한조회작업이취소되었으면_즉시cancelled에러를던진다() async {
        // Given
        let repository = MockVoiceRecordPermissionRepository()
        await repository.setResult(.success(()))
        await repository.expectCheckRecordingPermission(callCount: 0)

        let useCase = DefaultCheckOnBoardingMicrophonePermissionUseCase(repository: repository)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await useCase.execute()
        }

        do {
            _ = try await task.value
            XCTFail("작업이 즉시 취소되었으므로 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
            await repository.verify()
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }
}
