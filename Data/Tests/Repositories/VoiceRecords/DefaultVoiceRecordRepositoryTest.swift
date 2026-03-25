@testable import Data
import Domain
import Foundation
import XCTest

final class DefaultVoiceRecordRepositoryTest: XCTestCase {}

// MARK: - Start Recording

extension DefaultVoiceRecordRepositoryTest {
    func test_정상상태_녹음시작시_서비스의startRecording을호출한다() async throws {
        let audioService = MockAudioRecorderService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService)

        // Given
        let stubStream = AsyncStream<Waveform> { _ in }
        await audioService.setStartResult(.success(stubStream))
        await audioService.expectStart(callCount: 1)

        // When
        _ = try await sut.startRecording()

        // Then
        await audioService.verify()
    }

    func test_서비스실패상태_녹음시작시_startFailed에러를던진다() async throws {
        let audioService = MockAudioRecorderService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService)

        // Given
        await audioService.setStartResult(.failure(.startFailed))
        await audioService.expectStart(callCount: 1)

        // When & Then
        do {
            _ = try await sut.startRecording()
            XCTFail("VoiceRecordRepositoryError.startFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .startFailed = error else {
                return XCTFail("예상한 에러는 VoiceRecordRepositoryError.startFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await audioService.verify()
    }

    func test_태스크취소상태_녹음시작시_cancelled에러를던진다() async throws {
        let audioService = MockAudioRecorderService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService)

        // Given
        await audioService.expectStart(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.startRecording()
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("VoiceRecordRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? VoiceRecordRepositoryError else {
                return XCTFail("예상한 에러는 VoiceRecordRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await audioService.verify()
    }
}

// MARK: - Pause Recording

extension DefaultVoiceRecordRepositoryTest {
    func test_정상상태_녹음일시정지시_서비스의pauseRecording을호출한다() async throws {
        let audioService = MockAudioRecorderService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService)

        // Given
        await audioService.setPauseResult(.success(()))
        await audioService.expectPause(callCount: 1)

        // When
        try await sut.pauseRecording()

        // Then
        await audioService.verify()
    }

    func test_서비스실패상태_녹음일시정지시_pauseFailed에러를던진다() async throws {
        let audioService = MockAudioRecorderService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService)

        // Given
        await audioService.setPauseResult(.failure(.pauseFailed))
        await audioService.expectPause(callCount: 1)

        // When & Then
        do {
            try await sut.pauseRecording()
            XCTFail("VoiceRecordRepositoryError.pauseFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .pauseFailed = error else {
                return XCTFail("예상한 에러는 VoiceRecordRepositoryError.pauseFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await audioService.verify()
    }

    func test_태스크취소상태_녹음일시정지시_cancelled에러를던진다() async throws {
        let audioService = MockAudioRecorderService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService)

        // Given
        await audioService.expectPause(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await sut.pauseRecording()
        }

        // When & Then
        do {
            try await task.value
            XCTFail("VoiceRecordRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? VoiceRecordRepositoryError else {
                return XCTFail("예상한 에러는 VoiceRecordRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await audioService.verify()
    }
}

// MARK: - Resume Recording

extension DefaultVoiceRecordRepositoryTest {
    func test_정상상태_녹음재개시_서비스의resumeRecording을호출한다() async throws {
        let audioService = MockAudioRecorderService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService)

        // Given
        await audioService.setResumeResult(.success(()))
        await audioService.expectResume(callCount: 1)

        // When
        try await sut.resumeRecording()

        // Then
        await audioService.verify()
    }

    func test_서비스실패상태_녹음재개시_resumeFailed에러를던진다() async throws {
        let audioService = MockAudioRecorderService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService)

        // Given
        await audioService.setResumeResult(.failure(.resumeFailed))
        await audioService.expectResume(callCount: 1)

        // When & Then
        do {
            try await sut.resumeRecording()
            XCTFail("VoiceRecordRepositoryError.resumeFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .resumeFailed = error else {
                return XCTFail("예상한 에러는 VoiceRecordRepositoryError.resumeFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await audioService.verify()
    }

    func test_태스크취소상태_녹음재개시_cancelled에러를던진다() async throws {
        let audioService = MockAudioRecorderService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService)

        // Given
        await audioService.expectResume(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await sut.resumeRecording()
        }

        // When & Then
        do {
            try await task.value
            XCTFail("VoiceRecordRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? VoiceRecordRepositoryError else {
                return XCTFail("예상한 에러는 VoiceRecordRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await audioService.verify()
    }
}

// MARK: - Finish Recording

extension DefaultVoiceRecordRepositoryTest {
    func test_정상상태_녹음종료시_서비스결과를반환한다() async throws {
        let audioService = MockAudioRecorderService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService)

        // Given
        let createdAt = Date(timeIntervalSince1970: 1234)
        let audioFilePath = URL(fileURLWithPath: "/test/path.caf")
        let duration = 12.34
        let recordedAudio = RecordedAudio(
            createdAt: createdAt,
            audioFilePath: audioFilePath,
            duration: duration
        )
        await audioService.setFinishResult(.success(recordedAudio))
        await audioService.expectFinish(callCount: 1)

        // When
        let voiceRecord = try await sut.finishRecording()

        // Then
        XCTAssertEqual(voiceRecord.createdAt, createdAt)
        XCTAssertEqual(voiceRecord.audioFilePath, audioFilePath)
        XCTAssertEqual(voiceRecord.duration, duration, accuracy: 0.001)
        await audioService.verify()
    }

    func test_서비스종료실패상태_녹음종료시_encodingFailed에러를던진다() async throws {
        let audioService = MockAudioRecorderService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService)

        // Given
        await audioService.setFinishResult(.failure(.encodingFailed))
        await audioService.expectFinish(callCount: 1)

        // When & Then
        do {
            _ = try await sut.finishRecording()
            XCTFail("VoiceRecordRepositoryError.encodingFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .encodingFailed = error else {
                return XCTFail("예상한 에러는 VoiceRecordRepositoryError.encodingFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await audioService.verify()
    }

    func test_태스크취소상태_녹음종료시_cancelled에러를던진다() async throws {
        let audioService = MockAudioRecorderService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService)

        // Given
        await audioService.expectFinish(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.finishRecording()
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("VoiceRecordRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? VoiceRecordRepositoryError else {
                return XCTFail("예상한 에러는 VoiceRecordRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await audioService.verify()
    }
}

// MARK: - Check Permission

extension DefaultVoiceRecordRepositoryTest {
    func test_마이크권한허용상태_권한조회시_authorized를반환한다() async throws {
        let audioService = MockAudioRecorderService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService)

        // Given
        await audioService.setCheckResult(Domain.PermissionStatus.authorized)
        await audioService.expectCheckPermission(callCount: 1)

        // When
        let result = try await sut.checkMicrophonePermission()

        // Then
        XCTAssertEqual(result, Domain.PermissionStatus.authorized)
    }

    func test_마이크권한미결정상태_권한조회시_notDetermined를반환한다() async throws {
        let audioService = MockAudioRecorderService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService)

        // Given
        await audioService.setCheckResult(Domain.PermissionStatus.notDetermined)
        await audioService.expectCheckPermission(callCount: 1)

        // When
        let result = try await sut.checkMicrophonePermission()

        // Then
        XCTAssertEqual(result, Domain.PermissionStatus.notDetermined)
    }

    func test_태스크취소상태_권한조회시_cancelled에러를던진다() async throws {
        let audioService = MockAudioRecorderService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService)

        // Given
        await audioService.expectCheckPermission(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.checkMicrophonePermission()
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("VoiceRecordRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? VoiceRecordRepositoryError else {
                return XCTFail("예상한 에러는 VoiceRecordRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
    }
}

// MARK: - Request Permission

extension DefaultVoiceRecordRepositoryTest {
    func test_마이크권한허용상태_권한요청시_authorized를반환한다() async throws {
        let audioService = MockAudioRecorderService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService)

        // Given
        await audioService.setRequestResult(Domain.PermissionStatus.authorized)
        await audioService.expectRequestPermission(callCount: 1)

        // When
        let result = try await sut.requestMicrophonePermission()

        // Then
        XCTAssertEqual(result, Domain.PermissionStatus.authorized)
    }

    func test_태스크취소상태_권한요청시_cancelled에러를던진다() async throws {
        let audioService = MockAudioRecorderService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService)

        // Given
        await audioService.expectRequestPermission(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.requestMicrophonePermission()
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("VoiceRecordRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? VoiceRecordRepositoryError else {
                return XCTFail("예상한 에러는 VoiceRecordRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
    }
}
