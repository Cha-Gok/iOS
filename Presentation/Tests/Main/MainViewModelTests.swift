@testable import Presentation
import Domain
import DomainTesting
import XCTest

@MainActor
final class MockMainCoordinatorDelegate: MainCoordinatorDelegate {
    var pushTrashViewCalled = false
    var pushMyFolderViewCalled = false
    var pushVoiceNoteViewCalled = false
    var presentRecodingViewCalled = false
    var popCalled = false

    var pushedCategory: CategoryToggle?
    var pushedVoiceNote: VoiceNote?

    func pushTrashView() {
        pushTrashViewCalled = true
    }

    func pushMyFolderView(category: CategoryToggle) {
        pushMyFolderViewCalled = true
        pushedCategory = category
    }

    func pushVoiceNoteView(voiceNote: VoiceNote) {
        pushVoiceNoteViewCalled = true
        pushedVoiceNote = voiceNote
    }

    func presentRecodingView() {
        presentRecodingViewCalled = true
    }

    func pop() {
        popCalled = true
    }
}

@MainActor
final class MainViewModelTests: XCTestCase {
    // MARK: - SUT

    private struct SUT {
        let viewModel: MainViewModel
        let mockFolderRepo: MockFolderRepository
        let mockVoiceNoteRepo: MockVoiceNoteRepository
        let mockCoordinator: MockMainCoordinatorDelegate
    }

    private func makeSUT() -> SUT {
        let mockFolderRepo = MockFolderRepository()
        let mockVoiceNoteRepo = MockVoiceNoteRepository()
        let mockWasteBasketRepo = MockWasteBasketRepository()
        let mockCoordinator = MockMainCoordinatorDelegate()

        let viewModel = MainViewModel(
            voiceNoteUseCase: DefaultVoiceNoteUseCase(
                repository: mockVoiceNoteRepo,
                sttRepository: MockSTTRepository(),
                summaryRepository: MockSummaryRepository()
            ),
            fetchFolderUseCase: DefaultFetchFolderUseCase(repository: mockFolderRepo),
            wasteBasketRepository: mockWasteBasketRepo
        )
        viewModel.mainCoordinator = mockCoordinator

        return SUT(
            viewModel: viewModel,
            mockFolderRepo: mockFolderRepo,
            mockVoiceNoteRepo: mockVoiceNoteRepo,
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

    func test_updateVoiceNoteCategory_호출시_기본폴더보이스노트로드확인() async {
        // Given
        let sut = makeSUT()
        let expectedNotes = [VoiceNote.stub(title: "노트1"), VoiceNote.stub(title: "노트2")]
        await sut.mockVoiceNoteRepo.setFetchAllResult(.success(expectedNotes))
        await sut.mockVoiceNoteRepo.expectFetchAllFromDefaultFolder(callCount: 1)

        // When
        sut.viewModel.updateVoiceNoteCategory()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        await sut.mockVoiceNoteRepo.verify()
        XCTAssertEqual(sut.viewModel.categoryData[1].items.count, 2)
        if case .voiceNote(let note) = sut.viewModel.categoryData[1].items[0] {
            XCTAssertEqual(note.title, "노트1")
        } else {
            XCTFail("VoiceNote 타입이 아닙니다.")
        }
    }

    func test_updateRecentCategory_호출시_최근기록로드확인() async {
        // Given
        let sut = makeSUT()
        let expectedNotes = [VoiceNote.stub(title: "최신1"), VoiceNote.stub(title: "최신2")]
        await sut.mockVoiceNoteRepo.setFetchRecentResult(.success(expectedNotes))
        await sut.mockVoiceNoteRepo.expectFetchRecent(callCount: 1)

        // When
        sut.viewModel.updateRecentCategory()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        await sut.mockVoiceNoteRepo.verify()
        XCTAssertEqual(sut.viewModel.categoryData[0].items.count, 2)
        if case .voiceNote(let note) = sut.viewModel.categoryData[0].items[0] {
            XCTAssertEqual(note.title, "최신1")
        } else {
            XCTFail("VoiceNote 타입이 아닙니다.")
        }
    }

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
