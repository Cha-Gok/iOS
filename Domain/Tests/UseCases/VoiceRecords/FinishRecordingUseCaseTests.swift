@testable import Domain
import Foundation
import XCTest

final class FinishRecordingUseCaseTests: XCTestCase {
    private var recordingRepository: MockVoiceRecordFinishRepository!
    private var sut: DefaultFinishRecordingUseCase!

    override func setUp() {
        super.setUp()
        recordingRepository = MockVoiceRecordFinishRepository()
        sut = DefaultFinishRecordingUseCase(recordingRepository: recordingRepository)
    }

    override func tearDown() {
        recordingRepository = nil
        sut = nil
        super.tearDown()
    }
}

// MARK: - 성공

extension FinishRecordingUseCaseTests {
    func test_execute_녹음종료에성공하면_생성된VoiceRecord를반환한다() async throws {
        // Given
        let expectedRecord = VoiceRecord.stub()
        await recordingRepository.setResult(.success(expectedRecord))
        await recordingRepository.expectFinishRecording(callCount: 1)

        // When
        let record = try await sut.execute()

        // Then
        XCTAssertEqual(record.id, expectedRecord.id)
        XCTAssertEqual(record.audioFilePath, expectedRecord.audioFilePath)
        XCTAssertEqual(record.duration, expectedRecord.duration, accuracy: 0.001)
        await recordingRepository.verify()
    }
}

// MARK: - 실패 / 에러 매핑

extension FinishRecordingUseCaseTests {
    func test_execute_녹음중이아니면_notRecording에러를던진다() async {
        // Given
        await recordingRepository.setResult(.failure(.notRecording))
        await recordingRepository.expectFinishRecording(callCount: 1)

        // When
        do {
            _ = try await sut.execute()
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .notRecording = error else {
                return XCTFail("expected .notRecording, got \(error)")
            }
        }

        await recordingRepository.verify()
    }

    func test_execute_녹음종료에실패하면_finishFailed에러를던진다() async {
        // Given
        await recordingRepository.setResult(.failure(.finishFailed))
        await recordingRepository.expectFinishRecording(callCount: 1)

        // When
        do {
            _ = try await sut.execute()
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .finishFailed = error else {
                return XCTFail("expected .finishFailed, got \(error)")
            }
        }

        await recordingRepository.verify()
    }

    func test_execute_인코딩에실패하면_encodingFailed에러를던진다() async {
        // Given
        await recordingRepository.setResult(.failure(.encodingFailed))
        await recordingRepository.expectFinishRecording(callCount: 1)

        // When
        do {
            _ = try await sut.execute()
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .encodingFailed = error else {
                return XCTFail("expected .encodingFailed, got \(error)")
            }
        }

        await recordingRepository.verify()
    }

    func test_execute_녹음종료중취소되면_cancelled에러를던진다() async {
        // Given
        await recordingRepository.setResult(.failure(.cancelled))
        await recordingRepository.expectFinishRecording(callCount: 1)

        // When
        do {
            _ = try await sut.execute()
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            // Then
            guard case .cancelled = error else {
                return XCTFail("expected .cancelled, got \(error)")
            }
        }

        await recordingRepository.verify()
    }

    func test_execute_녹음종료중알수없는에러가발생하면_unknown에러를던진다() async {
        // Given
        let underlyingError = NSError(domain: "Test", code: 404)
        await recordingRepository.setResult(.failure(.unknown(underlyingError)))
        await recordingRepository.expectFinishRecording(callCount: 1)

        // When
        do {
            _ = try await sut.execute()
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

extension FinishRecordingUseCaseTests {
    func test_execute_실행전에태스크가취소되면_리포지토리호출없이cancelled에러를던진다() async {
        guard let sut else {
            XCTFail("sut은 반드시 설정되어야 합니다.")
            return
        }
        // Given
        await recordingRepository.setResult(.success(.stub()))
        await recordingRepository.expectFinishRecording(callCount: 0)

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
            guard case .cancelled = error as? FinishRecordingUseCaseError else {
                return XCTFail("expected .cancelled, got \(error)")
            }
            await recordingRepository.verify()
        }
    }
}
