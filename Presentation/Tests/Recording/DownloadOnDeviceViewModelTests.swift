@testable import Presentation
import Domain
import DomainTesting
import XCTest

@MainActor
final class MockDownloadOnDeviceCoordinator: DownloadOnDeviceCoordinatorDelegate {
    private(set) var dismissSheetCallCount = 0
    private(set) var completionValue: Bool?

    func dismissSheet(completion: Bool) {
        dismissSheetCallCount += 1
        completionValue = completion
    }
}

final class MockOnDeviceStatusUseCase: OnDeviceStatusUseCase, @unchecked Sendable {
    private var continuation: AsyncStream<OnDeviceStatus>.Continuation?
    private(set) var downloadCallCount = 0
    private(set) var cancelCallCount = 0
    private(set) var lastDownloadedModel: ChaGokModel?
    private(set) var lastCancelledModel: ChaGokModel?

    func subscribe(model: ChaGokModel) -> AsyncStream<OnDeviceStatus> {
        AsyncStream { cont in
            self.continuation = cont
            cont.yield(OnDeviceStatus(storage: .notDownloaded, runtime: .unloaded))
        }
    }

    func download(model: ChaGokModel) async throws(OnDeviceStatusUseCaseError) {
        downloadCallCount += 1
        lastDownloadedModel = model
    }

    func cancelDownload(model: ChaGokModel) {
        cancelCallCount += 1
        lastCancelledModel = model
    }

    func delete(model: ChaGokModel) async throws(DeleteOnDeviceRepositoryError) {
        // Mock delete implementation
    }

    func emit(status: OnDeviceStatus) {
        continuation?.yield(status)
    }
}

@MainActor
final class DownloadOnDeviceViewModelTests: XCTestCase {
    private struct SUT {
        let viewModel: DownloadOnDeviceViewModel
        let useCase: MockOnDeviceStatusUseCase
        let coordinator: MockDownloadOnDeviceCoordinator
    }

    private func makeSUT() -> SUT {
        let useCase = MockOnDeviceStatusUseCase()
        let coordinator = MockDownloadOnDeviceCoordinator()
        let viewModel = DownloadOnDeviceViewModel(onDeviceStatusUseCase: useCase)
        viewModel.coordinator = coordinator

        return SUT(
            viewModel: viewModel,
            useCase: useCase,
            coordinator: coordinator
        )
    }
}

// MARK: - 초기 상태

extension DownloadOnDeviceViewModelTests {
    func test_뷰모델생성시_초기상태를확인한다() {
        // Given & When
        let sut = makeSUT()

        // Then
        XCTAssertFalse(sut.viewModel.isDownloading)
        XCTAssertNil(sut.viewModel.progressFraction)
        XCTAssertNil(sut.viewModel.errorMessage)
        XCTAssertEqual(sut.viewModel.progressPercentText, "0%")
    }
}

// MARK: - 다운로드

extension DownloadOnDeviceViewModelTests {
    func test_다운로드중인상태가_전달되면_isDownloading이_true가되고_progressFraction이업데이트된다() async throws {
        // Given
        let sut = makeSUT()

        // When
        sut.useCase.emit(status: OnDeviceStatus(storage: .downloading(progress: 0.45), runtime: .unloaded))

        try await Task.sleep(nanoseconds: 50_000_000)

        // Then
        XCTAssertTrue(sut.viewModel.isDownloading)
        XCTAssertEqual(sut.viewModel.progressFraction, 0.45)
        XCTAssertEqual(sut.viewModel.progressPercentText, "45%")
    }

    func test_다운로드를_성공적으로_완료하면_coordinator의dismiss를호출한다() async throws {
        // Given
        let sut = makeSUT()

        // When
        sut.useCase.emit(status: OnDeviceStatus(storage: .downloaded, runtime: .unloaded))

        try await Task.sleep(nanoseconds: 50_000_000)

        // Then
        XCTAssertFalse(sut.viewModel.isDownloading)
        XCTAssertEqual(sut.viewModel.progressFraction, 1.0)
        XCTAssertEqual(sut.coordinator.dismissSheetCallCount, 1)
        XCTAssertTrue(sut.coordinator.completionValue ?? false)
    }

    func test_다운로드가_실패하면_errorMessage를_설정하고_isDownloading이_false가된다() async throws {
        // Given
        let sut = makeSUT()

        // When
        sut.useCase.emit(status: OnDeviceStatus(storage: .failed, runtime: .unloaded))

        try await Task.sleep(nanoseconds: 50_000_000)

        // Then
        XCTAssertFalse(sut.viewModel.isDownloading)
        XCTAssertNotNil(sut.viewModel.errorMessage)
        XCTAssertNil(sut.viewModel.progressFraction)
    }
}

// MARK: - 다운로드 취소 및 기타

extension DownloadOnDeviceViewModelTests {
    func test_cancelDownload_호출시_다운로드를취소하고_상태가초기화된다() {
        // Given
        let sut = makeSUT()
        sut.useCase.emit(status: OnDeviceStatus(storage: .downloading(progress: 0.5), runtime: .unloaded))

        // When
        sut.viewModel.cancelDownload()

        // Then
        XCTAssertFalse(sut.viewModel.isDownloading)
        XCTAssertNil(sut.viewModel.progressFraction)
    }

    func test_dismissError_호출시_errorMessage가_nil이된다() {
        // Given
        let sut = makeSUT()

        // When
        sut.useCase.emit(status: OnDeviceStatus(storage: .failed, runtime: .unloaded))
        sut.viewModel.dismissError()

        // Then
        XCTAssertNil(sut.viewModel.errorMessage)
    }
}
