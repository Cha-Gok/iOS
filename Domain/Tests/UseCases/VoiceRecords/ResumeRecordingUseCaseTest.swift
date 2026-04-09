@testable import Domain
import DomainTesting
import XCTest

final class ResumeRecordingUseCaseTest: XCTestCase {}

// MARK: - 성공 케이스

extension ResumeRecordingUseCaseTest {
    func test_정상상태_녹음재개시_리포지토리의재개메서드를호출한다() async throws {
        let recordingRepository = MockVoiceRecordRepository()
        let sut = DefaultResumeRecordingUseCase(recordingRepository: recordingRepository)

        // Given
        await recordingRepository.setResumeResult(.success(()))
        await recordingRepository.expectResumeRecording(callCount: 1)

        // When
        try await sut.execute()

        // Then
        await recordingRepository.verify()
    }
}

// MARK: - 에러 케이스

extension ResumeRecordingUseCaseTest {
    func test_일시정지상태아닌경우_녹음재개시_notPaused에러를던진다() async {
        let recordingRepository = MockVoiceRecordRepository()
        let sut = DefaultResumeRecordingUseCase(recordingRepository: recordingRepository)

        // Given
        await recordingRepository.setResumeResult(.failure(.notPaused))
        await recordingRepository.expectResumeRecording(callCount: 1)

        // When & Then
        do {
            try await sut.execute()
            XCTFail("ResumeRecordingUseCaseError.notPaused 에러를 throw 해야 합니다.")
        } catch {
            guard case .notPaused = error else {
                return XCTFail("예상한 에러는 ResumeRecordingUseCaseError.notPaused 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await recordingRepository.verify()
    }

    func test_태스크취소상태_녹음재개시_cancelled에러를던진다() async {
        let recordingRepository = MockVoiceRecordRepository()
        let sut = DefaultResumeRecordingUseCase(recordingRepository: recordingRepository)

        // Given
        await recordingRepository.expectResumeRecording(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await sut.execute()
        }

        // When & Then
        do {
            try await task.value
            XCTFail("ResumeRecordingUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? ResumeRecordingUseCaseError else {
                return XCTFail("예상한 에러는 ResumeRecordingUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await recordingRepository.verify()
    }
}
