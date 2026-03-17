import XCTest

@testable import Domain

final class ResumeRecordingUseCaseTests: XCTestCase {

    private var recordingRepository: MockVoiceRecordResumeRepository!
    private var sut: DefaultResumeRecordingUseCase!

    override func setUp() {
        super.setUp()
        recordingRepository = MockVoiceRecordResumeRepository()
        sut = DefaultResumeRecordingUseCase(recordingRepository: recordingRepository)
    }

    override func tearDown() {
        recordingRepository = nil
        sut = nil
        super.tearDown()
    }
}

// MARK: - 성공
extension ResumeRecordingUseCaseTests {

    func test_execute_녹음재개에성공하면_완료된다() async throws {
        // Given
        await recordingRepository.setResult(.success(()))
        await recordingRepository.expectResumeRecording(callCount: 1)

        // When
        try await sut.execute()

        // Then
        await recordingRepository.verify()
    }
}

// MARK: - 실패 / 에러 매핑
extension ResumeRecordingUseCaseTests {

    func test_execute_일시정지상태가아니면_notPaused에러를던진다() async {
        // Given
        await recordingRepository.setResult(.failure(.notPaused))
        await recordingRepository.expectResumeRecording(callCount: 1)

        // When
        do {
            try await sut.execute()
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .notPaused = error else {
                return XCTFail("expected .notPaused, got \(error)")
            }
        }

        // Then
        await recordingRepository.verify()
    }

    func test_execute_재개에실패하면_resumeFailed에러를던진다() async {
        // Given
        await recordingRepository.setResult(.failure(.resumeFailed))
        await recordingRepository.expectResumeRecording(callCount: 1)

        // When
        do {
            try await sut.execute()
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .resumeFailed = error else {
                return XCTFail("expected .resumeFailed, got \(error)")
            }
        }

        // Then
        await recordingRepository.verify()
    }

    func test_execute_재개중취소되면_cancelled에러를던진다() async {
        // Given
        await recordingRepository.setResult(.failure(.cancelled))
        await recordingRepository.expectResumeRecording(callCount: 1)

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

        // Then
        await recordingRepository.verify()
    }

    func test_execute_재개중알수없는에러가발생하면_unknown에러를던진다() async {
        // Given
        let underlyingError = NSError(domain: "Test", code: -999)
        await recordingRepository.setResult(.failure(.unknown(underlyingError)))
        await recordingRepository.expectResumeRecording(callCount: 1)

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

        // Then
        await recordingRepository.verify()
    }
}

// MARK: - Task 취소
extension ResumeRecordingUseCaseTests {

    func test_execute_실행전에태스크가취소되면_리포지토리호출없이cancelled에러를던진다() async {
        guard let sut else {
            XCTFail("sut은 반드시 설정되어야 합니다.")
            return
        }
        // Given
        await recordingRepository.setResult(.success(()))
        await recordingRepository.expectResumeRecording(callCount: 0)

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
            guard case .cancelled = error as? ResumeRecordingUseCaseError else {
                return XCTFail("expected .cancelled, got \(error)")
            }
            // Then
            await recordingRepository.verify()
        }
    }
}
