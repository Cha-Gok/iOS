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
    private struct SUT {
        let viewModel: RecordingViewModel
        let repository: MockVoiceRecordRepository
        let coordinator: MockRecordingCoordinator
    }

    private func makeSUT() -> SUT {
        let repository = MockVoiceRecordRepository()
        let coordinator = MockRecordingCoordinator()

        let viewModel = RecordingViewModel(
            startRecordingUseCase: DefaultStartRecordingUseCase(recordingRepository: repository),
            pauseRecordingUseCase: DefaultPauseRecordingUseCase(recordingRepository: repository),
            resumeRecordingUseCase: DefaultResumeRecordingUseCase(recordingRepository: repository),
            finishRecordingUseCase: DefaultFinishRecordingUseCase(recordingRepository: repository),
            cancelRecordingUseCase: DefaultCancelRecordingUseCase(recordingRepository: repository)
        )
        viewModel.coordinator = coordinator

        return SUT(viewModel: viewModel, repository: repository, coordinator: coordinator)
    }
}

// MARK: - 초기 상태

extension RecordingViewModelTests {
    func test_뷰모델생성시_초기상태를확인한다() {
        // Given & When
        let sut = makeSUT()

        // Then
        XCTAssertEqual(sut.viewModel.state.recordingState, .idle)
        XCTAssertEqual(sut.viewModel.state.amplitude, 0)
        XCTAssertNil(sut.viewModel.state.errorMessage)
        XCTAssertEqual(sut.viewModel.state.recordingDuration, 0)
    }
}

// MARK: - 녹음 시작

extension RecordingViewModelTests {
    func test_idle상태_recordButtonTapped_녹음을시작하고recording상태가된다() async {
        // Given
        let sut = makeSUT()
        let stream = AsyncStream<Waveform> { $0.finish() }
        await sut.repository.setStartResult(.success(stream))

        // When
        sut.viewModel.send(.recordButtonTapped)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.viewModel.state.recordingState, .recording)
        XCTAssertNil(sut.viewModel.state.errorMessage)
    }

    func test_idle상태_녹음시작실패시_idle상태를유지하고errorMessage를설정한다() async {
        // Given
        let sut = makeSUT()
        await sut.repository.setStartResult(.failure(.startFailed))

        // When
        sut.viewModel.send(.recordButtonTapped)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.viewModel.state.recordingState, .idle)
        XCTAssertNotNil(sut.viewModel.state.errorMessage)
    }
}

// MARK: - 녹음 일시정지

extension RecordingViewModelTests {
    func test_recording상태_recordButtonTapped_녹음을일시정지하고paused상태가된다() async {
        // Given
        let sut = makeSUT()
        let stream = AsyncStream<Waveform> { $0.finish() }
        await sut.repository.setStartResult(.success(stream))
        await sut.repository.setPauseResult(.success(()))

        sut.viewModel.send(.recordButtonTapped) // idle → recording
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        sut.viewModel.send(.recordButtonTapped) // recording → paused
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.viewModel.state.recordingState, .paused)
    }

    func test_recording상태_일시정지실패시_errorMessage를설정한다() async {
        // Given
        let sut = makeSUT()
        let stream = AsyncStream<Waveform> { $0.finish() }
        await sut.repository.setStartResult(.success(stream))
        await sut.repository.setPauseResult(.failure(.pauseFailed))

        sut.viewModel.send(.recordButtonTapped) // idle → recording
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        sut.viewModel.send(.recordButtonTapped) // recording → pause 실패
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertNotNil(sut.viewModel.state.errorMessage)
    }
}

// MARK: - 녹음 재개

extension RecordingViewModelTests {
    func test_paused상태_recordButtonTapped_녹음을재개하고recording상태가된다() async {
        // Given
        let sut = makeSUT()
        let stream = AsyncStream<Waveform> { $0.finish() }
        await sut.repository.setStartResult(.success(stream))
        await sut.repository.setPauseResult(.success(()))
        await sut.repository.setResumeResult(.success(()))

        sut.viewModel.send(.recordButtonTapped) // idle → recording
        try? await Task.sleep(nanoseconds: 100_000_000)
        sut.viewModel.send(.recordButtonTapped) // recording → paused
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        sut.viewModel.send(.recordButtonTapped) // paused → recording
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.viewModel.state.recordingState, .recording)
    }

    func test_paused상태_녹음재개실패시_errorMessage를설정한다() async {
        // Given
        let sut = makeSUT()
        let stream = AsyncStream<Waveform> { $0.finish() }
        await sut.repository.setStartResult(.success(stream))
        await sut.repository.setPauseResult(.success(()))
        await sut.repository.setResumeResult(.failure(.resumeFailed))

        sut.viewModel.send(.recordButtonTapped) // idle → recording
        try? await Task.sleep(nanoseconds: 100_000_000)
        sut.viewModel.send(.recordButtonTapped) // recording → paused
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        sut.viewModel.send(.recordButtonTapped) // paused → resume 실패
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertNotNil(sut.viewModel.state.errorMessage)
    }
}

// MARK: - 취소

extension RecordingViewModelTests {
    func test_cancelButtonTapped_녹음을중단하고coordinator의cancelRecording을호출한다() async {
        // Given
        let sut = makeSUT()
        await sut.repository.setCancelResult(.success(()))
        await sut.repository.expectCancelRecording(callCount: 1)

        // When
        sut.viewModel.send(.cancelButtonTapped)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.coordinator.cancelRecordingCallCount, 1)
        await sut.repository.verify()
    }
}

// MARK: - 완료

extension RecordingViewModelTests {
    func test_finishButtonTapped_녹음완료후coordinator의finishRecording을호출한다() async {
        // Given
        let sut = makeSUT()
        let stub = VoiceRecord.stub()
        await sut.repository.setFinishResult(.success(stub))

        // When
        sut.viewModel.send(.finishButtonTapped)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.coordinator.finishRecordingCallCount, 1)
        XCTAssertEqual(sut.coordinator.finishedVoiceRecord?.id, stub.id)
    }

    func test_finishButtonTapped_완료실패시_coordinator를호출하지않고errorMessage를설정한다() async {
        // Given
        let sut = makeSUT()
        await sut.repository.setFinishResult(.failure(.finishFailed))

        // When
        sut.viewModel.send(.finishButtonTapped)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.coordinator.finishRecordingCallCount, 0)
        XCTAssertNotNil(sut.viewModel.state.errorMessage)
    }
}
