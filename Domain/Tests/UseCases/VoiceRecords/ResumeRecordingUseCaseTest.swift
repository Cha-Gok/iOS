@testable import Domain
import XCTest

final class ResumeRecordingUseCaseTest: XCTestCase {
    private var recordingRepository: MockVoiceRecordResumeRepository!
    private var sut: DefaultResumeRecordingUseCase!

    override func setUp() {
        super.setUp()
        recordingRepository = MockVoiceRecordResumeRepository()
        sut = DefaultResumeRecordingUseCase(recordingRepository: recordingRepository)
    }

    override func tearDown() {
        recordingRepository = nil
        sut = nil
        super.tearDown()
    }
}

// MARK: - 성공 케이스

extension ResumeRecordingUseCaseTest {
    func test_정상상태_녹음재개시_리포지토리의재개메서드를호출한다() async throws {
        // Given
        await recordingRepository.setResult(.success(()))
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
        // Given
        await recordingRepository.setResult(.failure(.notPaused))
        await recordingRepository.expectResumeRecording(callCount: 1)

        // When & Then
        do {
            try await sut.execute()
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            guard case .notPaused = error else {
                return XCTFail("expected .notPaused, got \(error)")
            }
        }
        await recordingRepository.verify()
    }

    func test_태스크취소상태_녹음재개시_cancelled에러를던진다() async throws {
        // Given
        await recordingRepository.expectResumeRecording(callCount: 0)

        let sut = try XCTUnwrap(sut)
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await sut.execute()
        }

        // When & Then
        do {
            try await task.value
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? ResumeRecordingUseCaseError else {
                return XCTFail("expected .cancelled, got \(error)")
            }
        }
        await recordingRepository.verify()
    }
}
