@testable import Data
import Domain
import Foundation
import XCTest

final class DefaultVoiceRecordFinishRepositoryTest: XCTestCase {}

// MARK: - 성공 케이스

extension DefaultVoiceRecordFinishRepositoryTest {
    func test_정상상태_녹음종료시_서비스의finishRecording결과로VoiceRecord를반환한다() async throws {
        let service = MockAudioRecorderService()
        let sut = DefaultVoiceRecordFinishRepository(service: service)

        // Given
        let createdAt = Date(timeIntervalSince1970: 1234)
        let audioFilePath = URL(fileURLWithPath: "/test/path.caf")
        let duration = 12.34
        let recordedAudio = RecordedAudio(
            createdAt: createdAt,
            audioFilePath: audioFilePath,
            duration: duration
        )
        await service.setFinishResult(.success(recordedAudio))
        await service.expectFinish(callCount: 1)

        // When
        let voiceRecord = try await sut.finishRecording()

        // Then
        XCTAssertEqual(voiceRecord.createdAt, createdAt)
        XCTAssertEqual(voiceRecord.audioFilePath, audioFilePath)
        XCTAssertEqual(voiceRecord.duration, duration, accuracy: 0.001)
        await service.verify()
    }
}

// MARK: - 에러 케이스

extension DefaultVoiceRecordFinishRepositoryTest {
    func test_녹음중아닌상태_녹음종료시_notRecording에러를던진다() async throws {
        let service = MockAudioRecorderService()
        let sut = DefaultVoiceRecordFinishRepository(service: service)

        // Given
        await service.setFinishResult(.failure(.notRecording))
        await service.expectFinish(callCount: 1)

        // When & Then
        do {
            _ = try await sut.finishRecording()
            XCTFail("VoiceRecordFinishRepositoryError.notRecording 에러를 throw 해야 합니다.")
        } catch {
            guard case .notRecording = error else {
                return XCTFail(
                    "예상한 에러는 VoiceRecordFinishRepositoryError.notRecording 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await service.verify()
    }

    func test_서비스종료실패상태_녹음종료시_finishFailed에러를던진다() async throws {
        let service = MockAudioRecorderService()
        let sut = DefaultVoiceRecordFinishRepository(service: service)

        // Given
        await service.setFinishResult(.failure(.finishFailed))
        await service.expectFinish(callCount: 1)

        // When & Then
        do {
            _ = try await sut.finishRecording()
            XCTFail("VoiceRecordFinishRepositoryError.finishFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .finishFailed = error else {
                return XCTFail(
                    "예상한 에러는 VoiceRecordFinishRepositoryError.finishFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await service.verify()
    }

    func test_서비스인코딩실패상태_녹음종료시_encodingFailed에러를던진다() async throws {
        let service = MockAudioRecorderService()
        let sut = DefaultVoiceRecordFinishRepository(service: service)

        // Given
        await service.setFinishResult(.failure(.encodingFailed))
        await service.expectFinish(callCount: 1)

        // When & Then
        do {
            _ = try await sut.finishRecording()
            XCTFail("VoiceRecordFinishRepositoryError.encodingFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .encodingFailed = error else {
                return XCTFail(
                    "예상한 에러는 VoiceRecordFinishRepositoryError.encodingFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await service.verify()
    }
}

// MARK: - 취소 케이스

extension DefaultVoiceRecordFinishRepositoryTest {
    func test_태스크취소상태_녹음종료시_cancelled에러를던진다() async throws {
        let service = MockAudioRecorderService()
        let sut = DefaultVoiceRecordFinishRepository(service: service)

        // Given
        await service.expectFinish(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.finishRecording()
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("VoiceRecordFinishRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? VoiceRecordFinishRepositoryError else {
                return XCTFail(
                    "예상한 에러는 VoiceRecordFinishRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await service.verify()
    }
}
