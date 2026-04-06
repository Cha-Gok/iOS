@testable import Presentation
import Domain
import DomainTests
import XCTest

@MainActor
final class MockRecordingCoordinator: RecordingCoordinating {
    private(set) var cancelRecordingCallCount = 0
    private(set) var finishRecordingCallCount = 0
    private(set) var finishedVoiceRecord: VoiceRecord?

    func cancelRecording() {
        cancelRecordingCallCount += 1
    }

    func finishRecording(voiceRecord: VoiceRecord) {
        finishRecordingCallCount += 1
        finishedVoiceRecord = voiceRecord
    }
}

@MainActor
final class RecordingViewModelTests: XCTestCase {
    private func makeSUT() -> (
        sut: RecordingViewModel,
        repository: MockVoiceRecordRepository,
        coordinator: MockRecordingCoordinator
    ) {
        let repository = MockVoiceRecordRepository()
        let coordinator = MockRecordingCoordinator()

        let sut = RecordingViewModel(
            startRecordingUseCase: DefaultStartRecordingUseCase(recordingRepository: repository),
            pauseRecordingUseCase: DefaultPauseRecordingUseCase(recordingRepository: repository),
            resumeRecordingUseCase: DefaultResumeRecordingUseCase(recordingRepository: repository),
            finishRecordingUseCase: DefaultFinishRecordingUseCase(recordingRepository: repository)
        )
        sut.coordinator = coordinator

        return (sut, repository, coordinator)
    }
}

// MARK: - 초기 상태

extension RecordingViewModelTests {
    func test_뷰모델생성시_초기상태를확인한다() {
        // Given & When
        let (sut, _, _) = makeSUT()

        // Then
        XCTAssertEqual(sut.state.recordingState, .idle)
        XCTAssertEqual(sut.state.amplitude, 0)
        XCTAssertNil(sut.state.errorMessage)
        XCTAssertEqual(sut.state.recordingDuration, 0)
    }
}

// MARK: - 녹음 시작

extension RecordingViewModelTests {
    func test_idle상태_recordButtonTapped_녹음을시작하고recording상태가된다() async {
        // Given
        let (sut, repository, _) = makeSUT()
        let stream = AsyncStream<Waveform> { $0.finish() }
        await repository.setStartResult(.success(stream))

        // When
        sut.send(.recordButtonTapped)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.state.recordingState, .recording)
        XCTAssertNil(sut.state.errorMessage)
    }

    func test_idle상태_녹음시작실패시_idle상태를유지하고errorMessage를설정한다() async {
        // Given
        let (sut, repository, _) = makeSUT()
        await repository.setStartResult(.failure(.startFailed))

        // When
        sut.send(.recordButtonTapped)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.state.recordingState, .idle)
        XCTAssertNotNil(sut.state.errorMessage)
    }
}

// MARK: - 녹음 일시정지

extension RecordingViewModelTests {
    func test_recording상태_recordButtonTapped_녹음을일시정지하고paused상태가된다() async {
        // Given
        let (sut, repository, _) = makeSUT()
        let stream = AsyncStream<Waveform> { $0.finish() }
        await repository.setStartResult(.success(stream))
        await repository.setPauseResult(.success(()))

        sut.send(.recordButtonTapped) // idle → recording
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        sut.send(.recordButtonTapped) // recording → paused
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.state.recordingState, .paused)
    }

    func test_recording상태_일시정지실패시_errorMessage를설정한다() async {
        // Given
        let (sut, repository, _) = makeSUT()
        let stream = AsyncStream<Waveform> { $0.finish() }
        await repository.setStartResult(.success(stream))
        await repository.setPauseResult(.failure(.pauseFailed))

        sut.send(.recordButtonTapped) // idle → recording
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        sut.send(.recordButtonTapped) // recording → pause 실패
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertNotNil(sut.state.errorMessage)
    }
}

// MARK: - 녹음 재개

extension RecordingViewModelTests {
    func test_paused상태_recordButtonTapped_녹음을재개하고recording상태가된다() async {
        // Given
        let (sut, repository, _) = makeSUT()
        let stream = AsyncStream<Waveform> { $0.finish() }
        await repository.setStartResult(.success(stream))
        await repository.setPauseResult(.success(()))
        await repository.setResumeResult(.success(()))

        sut.send(.recordButtonTapped) // idle → recording
        try? await Task.sleep(nanoseconds: 100_000_000)
        sut.send(.recordButtonTapped) // recording → paused
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        sut.send(.recordButtonTapped) // paused → recording
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.state.recordingState, .recording)
    }

    func test_paused상태_녹음재개실패시_errorMessage를설정한다() async {
        // Given
        let (sut, repository, _) = makeSUT()
        let stream = AsyncStream<Waveform> { $0.finish() }
        await repository.setStartResult(.success(stream))
        await repository.setPauseResult(.success(()))
        await repository.setResumeResult(.failure(.resumeFailed))

        sut.send(.recordButtonTapped) // idle → recording
        try? await Task.sleep(nanoseconds: 100_000_000)
        sut.send(.recordButtonTapped) // recording → paused
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        sut.send(.recordButtonTapped) // paused → resume 실패
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertNotNil(sut.state.errorMessage)
    }
}

// MARK: - 취소

extension RecordingViewModelTests {
    func test_cancelButtonTapped_coordinator의cancelRecording을호출한다() {
        // Given
        let (sut, _, coordinator) = makeSUT()

        // When
        sut.send(.cancelButtonTapped)

        // Then
        XCTAssertEqual(coordinator.cancelRecordingCallCount, 1)
    }
}

// MARK: - 완료

extension RecordingViewModelTests {
    func test_finishButtonTapped_녹음완료후coordinator의finishRecording을호출한다() async {
        // Given
        let (sut, repository, coordinator) = makeSUT()
        let stub = VoiceRecord.stub()
        await repository.setFinishResult(.success(stub))

        // When
        sut.send(.finishButtonTapped)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(coordinator.finishRecordingCallCount, 1)
        XCTAssertEqual(coordinator.finishedVoiceRecord?.id, stub.id)
    }

    func test_finishButtonTapped_완료실패시_coordinator를호출하지않고errorMessage를설정한다() async {
        // Given
        let (sut, repository, coordinator) = makeSUT()
        await repository.setFinishResult(.failure(.finishFailed))

        // When
        sut.send(.finishButtonTapped)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(coordinator.finishRecordingCallCount, 0)
        XCTAssertNotNil(sut.state.errorMessage)
    }
}
