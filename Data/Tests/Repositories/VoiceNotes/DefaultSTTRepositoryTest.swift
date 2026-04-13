@testable import Data
import Domain
import XCTest

final class DefaultSTTRepositoryTest: XCTestCase {}

// MARK: - 전사 성공 케이스

extension DefaultSTTRepositoryTest {
    func test_정상상태_전사시_Transcript를반환한다() async throws {
        // Given
        let mockService = MockSTTService()
        let sut = DefaultSTTRepository(service: mockService)
        let audioURL = URL(fileURLWithPath: "/test/audio.m4a")
        await mockService.setResult(.success(STTResult(text: "테스트 전사 텍스트", segments: [])))
        await mockService.expectTranscribe(callCount: 1, audioFileURL: audioURL)

        // When
        let result = try await sut.transcribe(audioFileURL: audioURL)

        // Then
        XCTAssertEqual(result.text, "테스트 전사 텍스트")
        await mockService.verify()
    }
}

// MARK: - 전사 에러 케이스

extension DefaultSTTRepositoryTest {
    func test_서비스에러상태_전사시_transcribeFailed에러를던진다() async throws {
        // Given
        let mockService = MockSTTService()
        let sut = DefaultSTTRepository(service: mockService)
        let audioURL = URL(fileURLWithPath: "/test/audio.m4a")
        let serviceErrors: [STTServiceError] = [
            .transcribeFailed,
            .recognizerUnavailable,
            .alreadyTranscribing
        ]

        for serviceError in serviceErrors {
            // Given
            await mockService.setResult(.failure(serviceError))

            // When & Then
            do {
                _ = try await sut.transcribe(audioFileURL: audioURL)
                XCTFail("STTRepositoryError.transcribeFailed 에러를 throw 해야 합니다. (serviceError: \(serviceError))")
            } catch {
                guard case .transcribeFailed = error else {
                    return XCTFail(
                        "예상한 에러는 STTRepositoryError.transcribeFailed 이지만, "
                            + "실제 받은 에러는 \(error) 입니다. (serviceError: \(serviceError))"
                    )
                }
            }
        }
    }

    func test_서비스취소에러상태_전사시_cancelled에러를던진다() async throws {
        // Given
        let mockService = MockSTTService()
        let sut = DefaultSTTRepository(service: mockService)
        // STTServiceError.cancelled (서비스 레벨 취소) → STTRepositoryError.cancelled 매핑 검증
        await mockService.setResult(.failure(.cancelled))

        // When & Then
        do {
            _ = try await sut.transcribe(audioFileURL: URL(fileURLWithPath: "/test/audio.m4a"))
            XCTFail("STTRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error else {
                return XCTFail(
                    "예상한 에러는 STTRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
    }

    func test_알수없는에러상태_전사시_unknown에러를던진다() async throws {
        // Given
        let mockService = MockSTTService()
        let sut = DefaultSTTRepository(service: mockService)
        let underlyingError = NSError(domain: "TestDomain", code: -1)
        await mockService.setResult(.failure(.unknown(underlyingError)))

        // When & Then
        do {
            _ = try await sut.transcribe(audioFileURL: URL(fileURLWithPath: "/test/audio.m4a"))
            XCTFail("STTRepositoryError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown = error else {
                return XCTFail(
                    "예상한 에러는 STTRepositoryError.unknown 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
    }
}

// MARK: - 전사 취소 케이스

extension DefaultSTTRepositoryTest {
    func test_태스크취소상태_전사시_cancelled에러를던진다() async throws {
        // Given
        let mockService = MockSTTService()
        let sut = DefaultSTTRepository(service: mockService)
        await mockService.expectTranscribe(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.transcribe(audioFileURL: URL(fileURLWithPath: "/test/audio.m4a"))
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("STTRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? STTRepositoryError else {
                return XCTFail(
                    "예상한 에러는 STTRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await mockService.verify()
    }
}

// MARK: - 권한 확인 성공 케이스

extension DefaultSTTRepositoryTest {
    func test_STT권한허용상태_권한확인시_authorized를반환한다() async throws {
        let mockService = MockSTTService()
        let sut = DefaultSTTRepository(service: mockService)

        // Given
        await mockService.setCheckResult(.authorized)
        await mockService.expectCheck(callCount: 1)

        // When
        let result = try await sut.checkSTTPermission()

        // Then
        XCTAssertEqual(result, .authorized)
        await mockService.verify()
    }

    func test_STT권한거부상태_권한확인시_denied를반환한다() async throws {
        let mockService = MockSTTService()
        let sut = DefaultSTTRepository(service: mockService)

        // Given
        await mockService.setCheckResult(.denied)
        await mockService.expectCheck(callCount: 1)

        // When
        let result = try await sut.checkSTTPermission()

        // Then
        XCTAssertEqual(result, .denied)
        await mockService.verify()
    }

    func test_STT권한미결정상태_권한확인시_notDetermined를반환한다() async throws {
        let mockService = MockSTTService()
        let sut = DefaultSTTRepository(service: mockService)

        // Given
        await mockService.setCheckResult(.notDetermined)
        await mockService.expectCheck(callCount: 1)

        // When
        let result = try await sut.checkSTTPermission()

        // Then
        XCTAssertEqual(result, .notDetermined)
        await mockService.verify()
    }
}

// MARK: - 권한 확인 취소 케이스

extension DefaultSTTRepositoryTest {
    func test_태스크취소상태_권한확인시_cancelled에러를던진다() async throws {
        let mockService = MockSTTService()
        let sut = DefaultSTTRepository(service: mockService)

        // Given
        await mockService.expectCheck(callCount: 0)

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

        await mockService.verify()
    }
}

// MARK: - 권한 요청 성공 케이스

extension DefaultSTTRepositoryTest {
    func test_STT권한허용상태_권한요청시_authorized를반환한다() async throws {
        let mockService = MockSTTService()
        let sut = DefaultSTTRepository(service: mockService)

        // Given
        await mockService.setRequestResult(.authorized)
        await mockService.expectRequest(callCount: 1)

        // When
        let result = try await sut.requestSTTPermission()

        // Then
        XCTAssertEqual(result, .authorized)
        await mockService.verify()
    }

    func test_STT권한거부상태_권한요청시_denied를반환한다() async throws {
        let mockService = MockSTTService()
        let sut = DefaultSTTRepository(service: mockService)

        // Given
        await mockService.setRequestResult(.denied)
        await mockService.expectRequest(callCount: 1)

        // When
        let result = try await sut.requestSTTPermission()

        // Then
        XCTAssertEqual(result, .denied)
        await mockService.verify()
    }
}

// MARK: - 권한 요청 취소 케이스

extension DefaultSTTRepositoryTest {
    func test_태스크취소상태_권한요청시_cancelled에러를던진다() async throws {
        let mockService = MockSTTService()
        let sut = DefaultSTTRepository(service: mockService)

        // Given
        await mockService.expectRequest(callCount: 0)

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

        await mockService.verify()
    }
}
