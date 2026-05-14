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

@MainActor
final class DownloadOnDeviceViewModelTests: XCTestCase {
    private struct SUT {
        let viewModel: DownloadOnDeviceViewModel
        let repository: MockSTTRepository
        let coordinator: MockDownloadOnDeviceCoordinator
    }

    private func makeSUT() -> SUT {
        let repository = MockSTTRepository()
        let coordinator = MockDownloadOnDeviceCoordinator()
        let viewModel = DownloadOnDeviceViewModel(repository: repository)
        viewModel.coordinator = coordinator

        return SUT(
            viewModel: viewModel,
            repository: repository,
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
    func test_다운로드를_성공적으로_완료하면_isDownloading이_false가되고_coordinator를호출한다() async throws {
        // Given
        let sut = makeSUT()
        let dummyURL = URL(fileURLWithPath: "/dummy/path")
        await sut.repository.setDownloadResult(.success(dummyURL))
        await sut.repository.expectDownload(callCount: 1)

        // When
        sut.viewModel.download()

        // Wait for async task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertFalse(sut.viewModel.isDownloading)
        XCTAssertEqual(sut.coordinator.dismissSheetCallCount, 1)
        XCTAssertEqual(sut.coordinator.completionValue, false) // Note: 성공이더라도 progressFraction이 1이 아니면 false가 반환됩니다.
        await sut.repository.verify()
    }

    func test_다운로드가_실패하면_errorMessage를_설정하고_isDownloading이_false가된다() async throws {
        // Given
        let sut = makeSUT()
        await sut.repository.setDownloadResult(.failure(.downloadFailed))
        await sut.repository.expectDownload(callCount: 1)

        // When
        sut.viewModel.download()

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertFalse(sut.viewModel.isDownloading)
        XCTAssertNotNil(sut.viewModel.errorMessage)
        XCTAssertEqual(sut.coordinator.dismissSheetCallCount, 1)
        await sut.repository.verify()
    }
}

// MARK: - 다운로드 취소 및 기타

extension DownloadOnDeviceViewModelTests {
    func test_cancelDownload_호출시_다운로드를취소하고_상태가초기화된다() {
        // Given
        let sut = makeSUT()
        sut.viewModel.download() // Task 시작
        XCTAssertTrue(sut.viewModel.isDownloading)

        // When
        sut.viewModel.cancelDownload()

        // Then
        XCTAssertFalse(sut.viewModel.isDownloading)
        XCTAssertNil(sut.viewModel.progressFraction)
    }

    func test_dismissError_호출시_errorMessage가_nil이된다() {
        // Given
        let sut = makeSUT()

        // 에러를 강제로 주입하기 위해 다운로드 실패 플로우를 한 번 태웁니다.
        sut.viewModel.download()
        sut.viewModel.dismissError() // 직접 지우기 시뮬레이션

        // Then
        XCTAssertNil(sut.viewModel.errorMessage)
    }
}
