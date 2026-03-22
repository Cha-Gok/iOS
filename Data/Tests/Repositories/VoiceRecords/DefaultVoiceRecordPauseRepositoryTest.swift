@testable import Data
import Domain
import XCTest

final class DefaultVoiceRecordPauseRepositoryTest: XCTestCase {}

// MARK: - 성공 케이스

extension DefaultVoiceRecordPauseRepositoryTest {
    func test_정상상태_녹음일시정지시_서비스의pauseRecording을호출한다() async throws {
        let service = MockAudioRecorderService()
        let sut = DefaultVoiceRecordPauseRepository(service: service)

        // Given
        await service.setPauseResult(.success(()))
        await service.expectPause(callCount: 1)

        // When
        try await sut.pauseRecording()

        // Then
        await service.verify()
    }
}

// MARK: - 에러 케이스

extension DefaultVoiceRecordPauseRepositoryTest {
    func test_녹음중아닌상태_녹음일시정지시_notRecording에러를던진다() async throws {
        let service = MockAudioRecorderService()
        let sut = DefaultVoiceRecordPauseRepository(service: service)

        // Given
        await service.setPauseResult(.failure(.notRecording))
        await service.expectPause(callCount: 1)

        // When & Then
        do {
            try await sut.pauseRecording()
            XCTFail("VoiceRecordPauseRepositoryError.notRecording 에러를 throw 해야 합니다.")
        } catch {
            guard case .notRecording = error else {
                return XCTFail(
                    "예상한 에러는 VoiceRecordPauseRepositoryError.notRecording 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await service.verify()
    }

    func test_서비스실패상태_녹음일시정지시_pauseFailed에러를던진다() async throws {
        let service = MockAudioRecorderService()
        let sut = DefaultVoiceRecordPauseRepository(service: service)

        // Given
        await service.setPauseResult(.failure(.pauseFailed))
        await service.expectPause(callCount: 1)

        // When & Then
        do {
            try await sut.pauseRecording()
            XCTFail("VoiceRecordPauseRepositoryError.pauseFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .pauseFailed = error else {
                return XCTFail(
                    "예상한 에러는 VoiceRecordPauseRepositoryError.pauseFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await service.verify()
    }
}

// MARK: - 취소 케이스

extension DefaultVoiceRecordPauseRepositoryTest {
    func test_태스크취소상태_녹음일시정지시_cancelled에러를던진다() async throws {
        let service = MockAudioRecorderService()
        let sut = DefaultVoiceRecordPauseRepository(service: service)

        // Given
        await service.expectPause(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await sut.pauseRecording()
        }

        // When & Then
        do {
            try await task.value
            XCTFail("VoiceRecordPauseRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? VoiceRecordPauseRepositoryError else {
                return XCTFail(
                    "예상한 에러는 VoiceRecordPauseRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await service.verify()
    }
}
