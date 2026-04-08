@testable import Presentation
import Domain
import DomainTests
import XCTest

@MainActor
final class MockMainViewCoordinatorDelegate: MainViewCoordinatorDelegate {
    var pushTrashViewCalled = false
    var pushMyFolderViewCalled = false
    var presentRecodingViewCalled = false
    var popMyFolderViewCalled = false

    var pushedCategory: CategoryToggle?

    func pushTrashView() {
        pushTrashViewCalled = true
    }

    func pushMyFolderView(category: CategoryToggle) {
        pushMyFolderViewCalled = true
        pushedCategory = category
    }

    func presentRecodingView() {
        presentRecodingViewCalled = true
    }

    func popMyFolderView() {
        popMyFolderViewCalled = true
    }
}

@MainActor
final class MainViewModelTests: XCTestCase {
    // MARK: - SUT

    private struct SUT {
        let viewModel: MainViewModel
        let mockFolderRepo: MockFolderRepository
        let mockCoordinator: MockMainViewCoordinatorDelegate
    }

    private func makeSUT() -> SUT {
        let mockFolderRepo = MockFolderRepository()
        let mockCoordinator = MockMainViewCoordinatorDelegate()

        let viewModel = MainViewModel(
            fetchFolderUseCase: DefaultReadFolderUseCase(repository: mockFolderRepo)
        )
        viewModel.mainCoordinator = mockCoordinator

        return SUT(
            viewModel: viewModel,
            mockFolderRepo: mockFolderRepo,
            mockCoordinator: mockCoordinator
        )
    }

    // MARK: - Initial State Tests

    func test_초기상태_확인() {
        let sut = makeSUT()

        XCTAssertEqual(sut.viewModel.categoryData.count, 4)
        XCTAssertEqual(sut.viewModel.selectedCategoryIndex, 0)
        XCTAssertTrue(sut.viewModel.isEmptyList)
    }

    // MARK: - Action Tests

    func test_setSelectedCategoryIndex_휴지통선택시_화면전환() {
        let sut = makeSUT()

        sut.viewModel.setSelectedCategoryIndex(indexPath: IndexPath(item: 3, section: 0))

        XCTAssertTrue(sut.mockCoordinator.pushTrashViewCalled)
        XCTAssertEqual(sut.viewModel.selectedCategoryIndex, 0) // 다시 0으로 복구되는지 확인
    }

    func test_setSelectedCategoryIndex_개인폴더선택시_화면전환() {
        let sut = makeSUT()

        sut.viewModel.setSelectedCategoryIndex(indexPath: IndexPath(item: 2, section: 0))

        XCTAssertTrue(sut.mockCoordinator.pushMyFolderViewCalled)
        XCTAssertNotNil(sut.mockCoordinator.pushedCategory)
        XCTAssertEqual(sut.mockCoordinator.pushedCategory?.title, "개인 폴더")
        XCTAssertEqual(sut.viewModel.selectedCategoryIndex, 0)
    }

    func test_presentRecodingView_호출시_화면전환() {
        let sut = makeSUT()

        sut.viewModel.presentRecodingView()

        XCTAssertTrue(sut.mockCoordinator.presentRecodingViewCalled)
    }

    // MARK: - Update Tests

    func test_updateMyFolderCategory_호출시_데이터로드확인() async {
        let sut = makeSUT()
        let expectedFolders = [
            Folder(name: "테스트 폴더 1"),
            Folder(name: "테스트 폴더 2")
        ]

        await sut.mockFolderRepo.setFetchAllResult(.success(expectedFolders))
        await sut.mockFolderRepo.expectFetchAll(callCount: 1)

        sut.viewModel.updateMyFolderCategory()

        // Task 내부 비동기 대기
        try? await Task.sleep(nanoseconds: 300_000_000)

        await sut.mockFolderRepo.verify()
        XCTAssertEqual(sut.viewModel.categoryData[2].items.count, 2)

        if case .folder(let folder) = sut.viewModel.categoryData[2].items[0] {
            XCTAssertEqual(folder.name, "테스트 폴더 1")
        } else {
            XCTFail("Folder 타입이 아닙니다.")
        }
    }
}
