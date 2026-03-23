@testable import Data
import Domain
import XCTest

final class DefaultVoiceRecordResumeRepositoryTest: XCTestCase {}

// MARK: - 성공 케이스

extension DefaultVoiceRecordResumeRepositoryTest {
    func test_정상상태_녹음재개시_서비스의resumeRecording을호출한다() async throws {
        let service = MockAudioRecorderService()
        let sut = DefaultVoiceRecordResumeRepository(service: service)

        // Given
        await service.setResumeResult(.success(()))
        await service.expectResume(callCount: 1)

        // When
        try await sut.resumeRecording()

        // Then
        await service.verify()
    }
}

// MARK: - 에러 케이스

extension DefaultVoiceRecordResumeRepositoryTest {
    func test_일시정지상태아닌경우_녹음재개시_notPaused에러를던진다() async throws {
        let service = MockAudioRecorderService()
        let sut = DefaultVoiceRecordResumeRepository(service: service)

        // Given
        await service.setResumeResult(.failure(.notPaused))
        await service.expectResume(callCount: 1)

        // When & Then
        do {
            try await sut.resumeRecording()
            XCTFail("VoiceRecordResumeRepositoryError.notPaused 에러를 throw 해야 합니다.")
        } catch {
            guard case .notPaused = error else {
                return XCTFail(
                    "예상한 에러는 VoiceRecordResumeRepositoryError.notPaused 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await service.verify()
    }

    func test_서비스실패상태_녹음재개시_resumeFailed에러를던진다() async throws {
        let service = MockAudioRecorderService()
        let sut = DefaultVoiceRecordResumeRepository(service: service)

        // Given
        await service.setResumeResult(.failure(.resumeFailed))
        await service.expectResume(callCount: 1)

        // When & Then
        do {
            try await sut.resumeRecording()
            XCTFail("VoiceRecordResumeRepositoryError.resumeFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .resumeFailed = error else {
                return XCTFail(
                    "예상한 에러는 VoiceRecordResumeRepositoryError.resumeFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await service.verify()
    }
}

// MARK: - 취소 케이스

extension DefaultVoiceRecordResumeRepositoryTest {
    func test_태스크취소상태_녹음재개시_cancelled에러를던진다() async throws {
        let service = MockAudioRecorderService()
        let sut = DefaultVoiceRecordResumeRepository(service: service)

        // Given
        await service.expectResume(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await sut.resumeRecording()
        }

        // When & Then
        do {
            try await task.value
            XCTFail("VoiceRecordResumeRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? VoiceRecordResumeRepositoryError else {
                return XCTFail(
                    "예상한 에러는 VoiceRecordResumeRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await service.verify()
    }
}
