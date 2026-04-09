@testable import Data
import Domain
import Foundation
import XCTest

final class DefaultVoiceRecordRepositoryTest: XCTestCase {}

// MARK: - 녹음 시작 케이스

extension DefaultVoiceRecordRepositoryTest {
    func test_정상상태_녹음시작시_서비스의startRecording을호출한다() async throws {
        let audioService = MockAudioRecorderService()
        let storageService = MockStorageService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService, storageService: storageService)

        // Given
        let stubStream = AsyncStream<Waveform> { _ in }
        let tempURL = URL(fileURLWithPath: "/temp/recording.m4a")
        await storageService.setGenerateTempResult(Result<URL, StorageServiceError>.success(tempURL))
        await audioService.setStartResult(Result<AsyncStream<Waveform>, AudioRecorderServiceError>.success(stubStream))

        await storageService.expectGenerateTemp(callCount: 1)
        await audioService.expectStart(callCount: 1)

        // When
        _ = try await sut.startRecording()

        // Then
        await audioService.verify()
        await storageService.verify()
    }

    func test_정상상태_녹음시작시_임시파일명이날짜기반형식으로생성된다() async throws {
        let audioService = MockAudioRecorderService()
        let storageService = MockStorageService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService, storageService: storageService)

        // Given
        let stubStream = AsyncStream<Waveform> { _ in }
        let tempURL = URL(fileURLWithPath: "/temp/recording.m4a")
        await storageService.setGenerateTempResult(Result<URL, StorageServiceError>.success(tempURL))
        await audioService.setStartResult(Result<AsyncStream<Waveform>, AudioRecorderServiceError>.success(stubStream))

        // When
        _ = try await sut.startRecording()

        // Then
        let generatedFileName = await storageService.generatedTempFileName
        XCTAssertNotNil(generatedFileName)
        XCTAssertTrue(
            generatedFileName?.range(of: #"^\d{14}\.m4a$"#, options: .regularExpression) != nil,
            "임시 파일명이 날짜 기반 형식이어야 합니다. actual: \(generatedFileName ?? "nil")"
        )
    }

    func test_서비스실패상태_녹음시작시_startFailed에러를던진다() async throws {
        let audioService = MockAudioRecorderService()
        let storageService = MockStorageService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService, storageService: storageService)

        // Given
        let tempURL = URL(fileURLWithPath: "/temp/recording.m4a")
        await storageService.setGenerateTempResult(Result<URL, StorageServiceError>.success(tempURL))
        await storageService.setDeleteResult(Result<Void, StorageServiceError>.success(()))
        await audioService
            .setStartResult(Result<AsyncStream<Waveform>, AudioRecorderServiceError>
                .failure(AudioRecorderServiceError.startFailed))
        await audioService.expectStart(callCount: 1)
        await storageService.expectDelete(callCount: 1)

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
        await storageService.verify()
    }

    func test_태스크취소상태_녹음시작시_cancelled에러를던진다() async throws {
        let audioService = MockAudioRecorderService()
        let storageService = MockStorageService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService, storageService: storageService)

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

// MARK: - 녹음 일시정지 케이스

extension DefaultVoiceRecordRepositoryTest {
    func test_정상상태_녹음일시정지시_서비스의pauseRecording을호출한다() async throws {
        let audioService = MockAudioRecorderService()
        let storageService = MockStorageService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService, storageService: storageService)

        // Given
        await audioService.setPauseResult(Result<Void, AudioRecorderServiceError>.success(()))
        await audioService.expectPause(callCount: 1)

        // When
        try await sut.pauseRecording()

        // Then
        await audioService.verify()
    }

    func test_서비스실패상태_녹음일시정지시_pauseFailed에러를던진다() async throws {
        let audioService = MockAudioRecorderService()
        let storageService = MockStorageService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService, storageService: storageService)

        // Given
        await audioService
            .setPauseResult(Result<Void, AudioRecorderServiceError>.failure(AudioRecorderServiceError.pauseFailed))
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
        let storageService = MockStorageService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService, storageService: storageService)

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

// MARK: - 녹음 재개 케이스

extension DefaultVoiceRecordRepositoryTest {
    func test_정상상태_녹음재개시_서비스의resumeRecording을호출한다() async throws {
        let audioService = MockAudioRecorderService()
        let storageService = MockStorageService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService, storageService: storageService)

        // Given
        await audioService.setResumeResult(Result<Void, AudioRecorderServiceError>.success(()))
        await audioService.expectResume(callCount: 1)

        // When
        try await sut.resumeRecording()

        // Then
        await audioService.verify()
    }

    func test_서비스실패상태_녹음재개시_resumeFailed에러를던진다() async throws {
        let audioService = MockAudioRecorderService()
        let storageService = MockStorageService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService, storageService: storageService)

        // Given
        await audioService
            .setResumeResult(Result<Void, AudioRecorderServiceError>.failure(AudioRecorderServiceError.resumeFailed))
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
        let storageService = MockStorageService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService, storageService: storageService)

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

// MARK: - 녹음 종료 케이스

extension DefaultVoiceRecordRepositoryTest {
    func test_정상상태_녹음종료시_서비스결과를반환하고파일을이동한다() async throws {
        let audioService = MockAudioRecorderService()
        let storageService = MockStorageService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService, storageService: storageService)

        // Given
        let createdAt = Date(timeIntervalSince1970: 1234)
        let tempURL = URL(fileURLWithPath: "/temp/path.m4a")
        let permanentURL = URL(fileURLWithPath: "/permanent/path.m4a")
        let duration = 12.34
        let recordedAudio = RecordedAudio(
            createdAt: createdAt,
            audioFilePath: tempURL,
            duration: duration
        )
        await audioService.setFinishResult(Result<RecordedAudio, AudioRecorderServiceError>.success(recordedAudio))
        await storageService.setMoveFileResult(Result<URL, StorageServiceError>.success(permanentURL))

        await audioService.expectFinish(callCount: 1)
        await storageService.expectMoveFile(callCount: 1)

        // When
        let voiceRecord = try await sut.finishRecording()

        // Then
        XCTAssertEqual(voiceRecord.createdAt, createdAt)
        XCTAssertEqual(voiceRecord.audioFilePath, permanentURL)
        XCTAssertEqual(voiceRecord.duration, duration, accuracy: 0.001)

        let movedSourceURL = await storageService.movedSourceURL
        let movedDirectory = await storageService.movedDirectory
        let movedFileName = await storageService.movedFileName

        XCTAssertEqual(movedSourceURL, tempURL)
        XCTAssertEqual(movedDirectory, "VoiceRecords")
        XCTAssertEqual(movedFileName, "\(createdAt.yyyyMMddHHmmssString).m4a")

        await audioService.verify()
        await storageService.verify()
    }

    func test_서비스종료실패상태_녹음종료시_encodingFailed에러를던진다() async throws {
        let audioService = MockAudioRecorderService()
        let storageService = MockStorageService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService, storageService: storageService)

        // Given
        await audioService
            .setFinishResult(Result<RecordedAudio, AudioRecorderServiceError>
                .failure(AudioRecorderServiceError.encodingFailed))
        await audioService.setCurrentURL(URL(fileURLWithPath: "/temp/path.m4a"))
        await storageService.setDeleteResult(Result<Void, StorageServiceError>.success(()))
        await audioService.expectFinish(callCount: 1)
        await storageService.expectDelete(callCount: 1)

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
        await storageService.verify()
    }

    func test_태스크취소상태_녹음종료시_cancelled에러를던진다() async throws {
        let audioService = MockAudioRecorderService()
        let storageService = MockStorageService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService, storageService: storageService)

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

// MARK: - 권한 확인 케이스

extension DefaultVoiceRecordRepositoryTest {
    func test_마이크권한허용상태_권한조회시_authorized를반환한다() async throws {
        let audioService = MockAudioRecorderService()
        let storageService = MockStorageService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService, storageService: storageService)

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
        let storageService = MockStorageService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService, storageService: storageService)

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
        let storageService = MockStorageService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService, storageService: storageService)

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

// MARK: - 권한 요청 케이스

extension DefaultVoiceRecordRepositoryTest {
    func test_마이크권한허용상태_권한요청시_authorized를반환한다() async throws {
        let audioService = MockAudioRecorderService()
        let storageService = MockStorageService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService, storageService: storageService)

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
        let storageService = MockStorageService()
        let sut = DefaultVoiceRecordRepository(audioService: audioService, storageService: storageService)

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
