@testable import Domain
import XCTest

final class PauseRecordingUseCaseTests: XCTestCase {
    private var recordingRepository: MockVoiceRecordPauseRepository!
    private var sut: DefaultPauseRecordingUseCase!

    override func setUp() {
        super.setUp()
        recordingRepository = MockVoiceRecordPauseRepository()
        sut = DefaultPauseRecordingUseCase(recordingRepository: recordingRepository)
    }

    override func tearDown() {
        recordingRepository = nil
        sut = nil
        super.tearDown()
    }
}

// MARK: - 성공

extension PauseRecordingUseCaseTests {
    func test_execute_녹음일시정지에성공하면_완료된다() async throws {
        // Given
        await recordingRepository.setResult(.success(()))
        await recordingRepository.expectPauseRecording(callCount: 1)

        // When
        try await sut.execute()

        // Then
        await recordingRepository.verify()
    }
}

// MARK: - 실패 / 에러 매핑

extension PauseRecordingUseCaseTests {
    func test_execute_녹음중이아니면_notRecording에러를던진다() async {
        // Given
        await recordingRepository.setResult(.failure(.notRecording))
        await recordingRepository.expectPauseRecording(callCount: 1)

        // When
        do {
            try await sut.execute()
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .notRecording = error else {
                return XCTFail("expected .notRecording, got \(error)")
            }
        }

        await recordingRepository.verify()
    }

    func test_execute_일시정지에실패하면_pauseFailed에러를던진다() async {
        // Given
        await recordingRepository.setResult(.failure(.pauseFailed))
        await recordingRepository.expectPauseRecording(callCount: 1)

        // When
        do {
            try await sut.execute()
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .pauseFailed = error else {
                return XCTFail("expected .pauseFailed, got \(error)")
            }
        }

        await recordingRepository.verify()
    }

    func test_execute_일시정지중취소되면_cancelled에러를던진다() async {
        // Given
        await recordingRepository.setResult(.failure(.cancelled))
        await recordingRepository.expectPauseRecording(callCount: 1)

        // When
        do {
            try await sut.execute()
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .cancelled = error else {
                return XCTFail("expected .cancelled, got \(error)")
            }
        }

        await recordingRepository.verify()
    }

    func test_execute_일시정지중알수없는에러가발생하면_unknown에러를던진다() async {
        // Given
        let underlyingError = NSError(domain: "Test", code: 123)
        await recordingRepository.setResult(.failure(.unknown(underlyingError)))
        await recordingRepository.expectPauseRecording(callCount: 1)

        // When
        do {
            try await sut.execute()
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .unknown(let wrappedError) = error else {
                return XCTFail("expected .unknown, got \(error)")
            }
            XCTAssertEqual(wrappedError as NSError, underlyingError)
        }

        await recordingRepository.verify()
    }
}

// MARK: - Task 취소

extension PauseRecordingUseCaseTests {
    func test_execute_실행전에태스크가취소되면_리포지토리호출없이cancelled에러를던진다() async {
        guard let sut else {
            XCTFail("sut은 반드시 설정되어야 합니다.")
            return
        }
        // Given
        await recordingRepository.setResult(.success(()))
        await recordingRepository.expectPauseRecording(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.execute()
        }

        // When
        do {
            _ = try await task.value
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .cancelled = error as? PauseRecordingUseCaseError else {
                return XCTFail("expected .cancelled, got \(error)")
            }
            await recordingRepository.verify()
        }
    }
}
