@testable import Domain
import XCTest

final class PauseRecordingUseCaseTest: XCTestCase {
    private var recordingRepository: MockVoiceRecordPauseRepository!
    private var sut: DefaultPauseRecordingUseCase!

    override func setUp() {
        super.setUp()
        recordingRepository = MockVoiceRecordPauseRepository()
        sut = DefaultPauseRecordingUseCase(recordingRepository: recordingRepository)
    }

    override func tearDown() {
        recordingRepository = nil
        sut = nil
        super.tearDown()
    }
}

// MARK: - 성공 케이스

extension PauseRecordingUseCaseTest {
    func test_정상상태_녹음일시정지시_리포지토리의일시정지메서드를호출한다() async throws {
        // Given
        await recordingRepository.setResult(.success(()))
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
        // Given
        await recordingRepository.setResult(.failure(.notRecording))
        await recordingRepository.expectPauseRecording(callCount: 1)

        // When & Then
        do {
            try await sut.execute()
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            guard case .notRecording = error else {
                return XCTFail("expected .notRecording, got \(error)")
            }
        }
        await recordingRepository.verify()
    }

    func test_태스크취소상태_녹음일시정지시_cancelled에러를던진다() async throws {
        guard let sut else {
            return XCTFail("sut가 초기화되지 않았습니다.")
        }
        // Given
        await recordingRepository.expectPauseRecording(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await sut.execute()
        }

        // When & Then
        do {
            try await task.value
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? PauseRecordingUseCaseError else {
                return XCTFail("expected .cancelled, got \(error)")
            }
        }
        await recordingRepository.verify()
    }
}
