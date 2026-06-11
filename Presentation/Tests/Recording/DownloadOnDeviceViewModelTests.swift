@testable import Presentation
import Domain
import DomainTesting
import XCTest

@MainActor
final class MockDownloadOnDeviceCoordinator: DownloadOnDeviceCoordinatorDelegate {
    private(set) var dismissSheetCallCount = 0

    func dismissSheet() {
        dismissSheetCallCount += 1
    }
}

final class DownloadMockOnDeviceStatusUseCase: OnDeviceStatusUseCase, @unchecked Sendable {
    private(set) var downloadCallCount = 0
    private(set) var deleteCallCount = 0
    private(set) var lastDownloadedModel: ChaGokModel?
    private(set) var lastDeletedModel: ChaGokModel?

    func subscribe(model: ChaGokModel) -> AsyncStream<OnDeviceStatus> {
        AsyncStream { cont in
            cont.yield(OnDeviceStatus(storage: .notDownloaded))
            cont.finish()
        }
    }

    func download(model: ChaGokModel) async throws(OnDeviceStatusUseCaseError) {
        downloadCallCount += 1
        lastDownloadedModel = model
    }

    func cancelDownload(model: ChaGokModel) {
        // Not used by the VM directly (VM uses downloadTask cancellation + delete)
    }

    func delete(model: ChaGokModel) async throws(DeleteOnDeviceRepositoryError) {
        deleteCallCount += 1
        lastDeletedModel = model
    }

    func checkStatus(model: ChaGokModel) async -> OnDeviceStatus {
        return OnDeviceStatus(storage: .notDownloaded)
    }

    func fetchModelSize(model: ChaGokModel) async -> String {
        return "약 75 MB"
    }
}

@MainActor
final class DownloadOnDeviceViewModelTests: XCTestCase {
    private struct SUT {
        let viewModel: DownloadOnDeviceViewModel
        let useCase: DownloadMockOnDeviceStatusUseCase
        let coordinator: MockDownloadOnDeviceCoordinator
    }

    private func makeSUT() -> SUT {
        let useCase = DownloadMockOnDeviceStatusUseCase()
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

// MARK: - 초기 상태 및 기본 호출 검사

extension DownloadOnDeviceViewModelTests {
    func test_뷰모델생성시_초기상태를확인한다() {
        // Given & When
        let sut = makeSUT()

        // Then
        XCTAssertFalse(sut.viewModel.isDownloading)
        XCTAssertNil(sut.viewModel.errorMessage)
        XCTAssertEqual(sut.viewModel.status.storage, .notDownloaded)
    }

    func test_download호출시_유즈케이스의download를호출한다() async {
        // Given
        let sut = makeSUT()

        // When
        sut.viewModel.download()

        // 비동기 Task 내부에서 유즈케이스 메소드가 호출될 때까지 대기
        let start = Date()
        while sut.useCase.downloadCallCount == 0 {
            if Date().timeIntervalSince(start) > 1.0 {
                XCTFail("Timeout waiting for download call")
                return
            }
            await Task.yield()
        }

        // Then
        XCTAssertEqual(sut.useCase.downloadCallCount, 1)
        XCTAssertEqual(sut.useCase.lastDownloadedModel, .whisper)
    }

    func test_cancelDownload호출시_상태를초기화하고_유즈케이스의delete를호출한다() async {
        // Given
        let sut = makeSUT()

        // When
        sut.viewModel.cancelDownload()

        // Then
        XCTAssertFalse(sut.viewModel.isDownloading)
        XCTAssertEqual(sut.viewModel.status.storage, .notDownloaded)

        // 비동기 Task 내부에서 유즈케이스 메소드가 호출될 때까지 대기
        let start = Date()
        while sut.useCase.deleteCallCount == 0 {
            if Date().timeIntervalSince(start) > 1.0 {
                XCTFail("Timeout waiting for delete call")
                return
            }
            await Task.yield()
        }

        XCTAssertEqual(sut.useCase.deleteCallCount, 1)
        XCTAssertEqual(sut.useCase.lastDeletedModel, .whisper)
    }

    func test_dismiss호출시_coordinator의dismissSheet를호출한다() {
        // Given
        let sut = makeSUT()

        // When
        sut.viewModel.dismiss()

        // Then
        XCTAssertEqual(sut.coordinator.dismissSheetCallCount, 1)
    }
}
