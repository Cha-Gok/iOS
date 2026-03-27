@testable import Domain
import XCTest

final class PauseRecordingUseCaseTest: XCTestCase {}

// MARK: - 성공 케이스

extension PauseRecordingUseCaseTest {
    func test_정상상태_녹음일시정지시_리포지토리의일시정지메서드를호출한다() async throws {
        let recordingRepository = MockVoiceRecordRepository()
        let sut = DefaultPauseRecordingUseCase(recordingRepository: recordingRepository)

        // Given
        await recordingRepository.setPauseResult(.success(()))
        await recordingRepository.expectPauseRecording(callCount: 1)

        // When
        try await sut.execute()

        // Then
        await recordingRepository.verify()
    }
}

// MARK: - 에러 케이스

extension PauseRecordingUseCaseTest {
    func test_녹음중아닌상태_녹음일시정지시_notRecording에러를던진다() async {
        let recordingRepository = MockVoiceRecordRepository()
        let sut = DefaultPauseRecordingUseCase(recordingRepository: recordingRepository)

        // Given
        await recordingRepository.setPauseResult(.failure(.notRecording))
        await recordingRepository.expectPauseRecording(callCount: 1)

        // When & Then
        do {
            try await sut.execute()
            XCTFail("PauseRecordingUseCaseError.notRecording 에러를 throw 해야 합니다.")
        } catch {
            guard case .notRecording = error else {
                return XCTFail("예상한 에러는 PauseRecordingUseCaseError.notRecording 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await recordingRepository.verify()
    }

    func test_태스크취소상태_녹음일시정지시_cancelled에러를던진다() async {
        let recordingRepository = MockVoiceRecordRepository()
        let sut = DefaultPauseRecordingUseCase(recordingRepository: recordingRepository)

        // Given
        await recordingRepository.expectPauseRecording(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await sut.execute()
        }

        // When & Then
        do {
            try await task.value
            XCTFail("PauseRecordingUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? PauseRecordingUseCaseError else {
                return XCTFail("예상한 에러는 PauseRecordingUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await recordingRepository.verify()
    }
}
