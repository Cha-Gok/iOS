@testable import Data
import Domain
import XCTest

final class DefaultSTTRepositoryTest: XCTestCase {
    private var mockService: MockSTTService!
    private var sut: DefaultSTTRepository!

    override func setUp() {
        super.setUp()
        mockService = MockSTTService()
        sut = DefaultSTTRepository(service: mockService)
    }

    override func tearDown() {
        mockService = nil
        sut = nil
        super.tearDown()
    }
}

// MARK: - 성공 케이스

extension DefaultSTTRepositoryTest {
    func test_정상상태_전사시_Transcript를반환한다() async throws {
        // Given
        let audioURL = URL(fileURLWithPath: "/test/audio.m4a")
        await mockService.setResult(.success("테스트 전사 텍스트"))
        await mockService.expectTranscribe(callCount: 1, audioFileURL: audioURL)

        // When
        let result = try await sut.transcribe(audioFileURL: audioURL)

        // Then
        XCTAssertEqual(result.text, "테스트 전사 텍스트")
        await mockService.verify()
    }
}

// MARK: - 에러 케이스

extension DefaultSTTRepositoryTest {
    func test_전사실패상태_전사시_transcribeFailed에러를던진다() async throws {
        // Given
        await mockService.setResult(.failure(.transcribeFailed))

        // When & Then
        do {
            _ = try await sut.transcribe(audioFileURL: URL(fileURLWithPath: "/test/audio.m4a"))
            XCTFail("STTRepositoryError.transcribeFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .transcribeFailed = error else {
                return XCTFail(
                    "예상한 에러는 STTRepositoryError.transcribeFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
    }

    func test_인식기불가상태_전사시_transcribeFailed에러를던진다() async throws {
        // Given
        await mockService.setResult(.failure(.recognizerUnavailable))

        // When & Then
        do {
            _ = try await sut.transcribe(audioFileURL: URL(fileURLWithPath: "/test/audio.m4a"))
            XCTFail("STTRepositoryError.transcribeFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .transcribeFailed = error else {
                return XCTFail(
                    "예상한 에러는 STTRepositoryError.transcribeFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
    }

    func test_이미전사중상태_전사시_transcribeFailed에러를던진다() async throws {
        // Given
        await mockService.setResult(.failure(.alreadyTranscribing))

        // When & Then
        do {
            _ = try await sut.transcribe(audioFileURL: URL(fileURLWithPath: "/test/audio.m4a"))
            XCTFail("STTRepositoryError.transcribeFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .transcribeFailed = error else {
                return XCTFail(
                    "예상한 에러는 STTRepositoryError.transcribeFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
    }

    func test_서비스취소에러상태_전사시_cancelled에러를던진다() async throws {
        // Given
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

// MARK: - 취소 케이스

extension DefaultSTTRepositoryTest {
    func test_태스크취소상태_전사시_cancelled에러를던진다() async throws {
        let mockService = MockSTTService()
        let sut = DefaultSTTRepository(service: mockService)

        // Given
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
