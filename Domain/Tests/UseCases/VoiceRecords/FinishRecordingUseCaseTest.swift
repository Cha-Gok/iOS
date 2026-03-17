@testable import Domain
import Foundation
import XCTest

final class FinishRecordingUseCaseTest: XCTestCase {
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

// MARK: - 성공 케이스

extension FinishRecordingUseCaseTest {
    func test_정상상태_녹음종료시_생성된VoiceRecord를반환한다() async throws {
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

// MARK: - 에러 케이스

extension FinishRecordingUseCaseTest {
    func test_녹음중아닌상태_녹음종료시_notRecording에러를던진다() async {
        // Given
        await recordingRepository.setResult(.failure(.notRecording))
        await recordingRepository.expectFinishRecording(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            guard case .notRecording = error else {
                return XCTFail("expected .notRecording, got \(error)")
            }
        }

        await recordingRepository.verify()
    }

    func test_리포지토리종료실패상태_녹음종료시_finishFailed에러를던진다() async {
        // Given
        await recordingRepository.setResult(.failure(.finishFailed))
        await recordingRepository.expectFinishRecording(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            guard case .finishFailed = error else {
                return XCTFail("expected .finishFailed, got \(error)")
            }
        }

        await recordingRepository.verify()
    }

    func test_인코딩실패상태_녹음종료시_encodingFailed에러를던진다() async {
        // Given
        await recordingRepository.setResult(.failure(.encodingFailed))
        await recordingRepository.expectFinishRecording(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            guard case .encodingFailed = error else {
                return XCTFail("expected .encodingFailed, got \(error)")
            }
        }

        await recordingRepository.verify()
    }

    func test_알수없는에러발생상태_녹음종료시_unknown에러를던진다() async {
        // Given
        let underlyingError = NSError(domain: "Test", code: 404)
        await recordingRepository.setResult(.failure(.unknown(underlyingError)))
        await recordingRepository.expectFinishRecording(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let wrappedError) = error else {
                return XCTFail("expected .unknown, got \(error)")
            }
            XCTAssertEqual(wrappedError as NSError, underlyingError)
        }

        await recordingRepository.verify()
    }

    func test_태스크취소상태_녹음종료시_cancelled에러를던진다() async throws {
        guard let sut else {
            return XCTFail("sut가 초기화되지 않았습니다.")
        }
        // Given
        await recordingRepository.setResult(.success(.stub()))
        await recordingRepository.expectFinishRecording(callCount: 0)
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.execute()
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? FinishRecordingUseCaseError else {
                return XCTFail("expected .cancelled, got \(error)")
            }
        }
        await recordingRepository.verify()
    }
}
