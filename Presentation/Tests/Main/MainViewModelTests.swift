@testable import Presentation
import Domain
import DomainTesting
import XCTest

@MainActor
final class MockMainCoordinatorDelegate: MainCoordinatorDelegate {
    var pushTrashViewCalled = false
    var pushMyFolderViewCalled = false
    var pushVoiceNoteViewCalled = false
    var pushSearchViewCalled = false
    var presentRecodingViewCalled = false
    var pushSettingViewCalled = false
    var popCalled = false

    var pushedCategory: CategoryToggle?
    var pushedVoiceNote: VoiceNote?
    var pushedSearchType: SearchViewModel.SearchType?
    var pushedSearchItems: [ContentItem] = []

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

    func pushSearchView(type: Presentation.SearchViewModel.SearchType, items: [Domain.ContentItem]) {
        pushSearchViewCalled = true
        pushedSearchType = type
        pushedSearchItems = items
    }

    func pushSettingView() {
        pushSettingViewCalled = true
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
        let mockVoiceRecordRepo: MockVoiceRecordRepository
        let mockFolderRepo: MockFolderRepository
        let mockVoiceNoteRepo: MockVoiceNoteRepository
        let mockCoordinator: MockMainCoordinatorDelegate
        let mockLanguageRepo: MockLanguageRepository
    }

    private func makeStream<T: Sendable>(_ items: T) -> AsyncStream<T> {
        AsyncStream { continuation in
            continuation.yield(items)
            continuation.finish()
        }
    }

    private func makeSUT() -> SUT {
        let mockVoiceRecordRepo = MockVoiceRecordRepository()
        let mockFolderRepo = MockFolderRepository()
        let mockVoiceNoteRepo = MockVoiceNoteRepository()
        let mockCoordinator = MockMainCoordinatorDelegate()
        let mockLanguageRepo = MockLanguageRepository()

        let viewModel = MainViewModel(
            microphoneRepository: mockVoiceRecordRepo,
            voiceNoteUseCase: DefaultVoiceNoteUseCase(
                repository: mockVoiceNoteRepo,
                folderRepository: mockFolderRepo,
                analysisService: MockVoiceNoteAnalysisService()
            ),
            folderUseCase: DefaultFolderUseCase(repository: mockFolderRepo)
        )
        viewModel.mainCoordinator = mockCoordinator

        return SUT(
            viewModel: viewModel,
            mockVoiceRecordRepo: mockVoiceRecordRepo,
            mockFolderRepo: mockFolderRepo,
            mockVoiceNoteRepo: mockVoiceNoteRepo,
            mockCoordinator: mockCoordinator,
            mockLanguageRepo: mockLanguageRepo
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

    func test_pushVoiceNoteView_호출시_화면전환() {
        let sut = makeSUT()
        let note = VoiceNote.stub(title: "테스트 노트")

        sut.viewModel.pushVoiceNoteView(voiceNote: note)

        XCTAssertTrue(sut.mockCoordinator.pushVoiceNoteViewCalled)
        XCTAssertEqual(sut.mockCoordinator.pushedVoiceNote?.id, note.id)
    }

    func test_pushSettingView_호출시_화면전환() {
        let sut = makeSUT()
        sut.viewModel.pushSettingView()

        XCTAssertTrue(sut.mockCoordinator.pushSettingViewCalled)
    }

    func test_pushSearchView_호출시_화면전환() async {
        // Given
        let sut = makeSUT()
        let note = VoiceNote.stub(title: "검색용 노트")
        let folder = Folder(name: "검색용 폴더", kind: .custom)

        // Mock 데이터 설정
        sut.mockVoiceNoteRepo.setObserveRecentResult(.success(makeStream([note])))
        sut.mockFolderRepo.setObserveByKindResult(.custom, result: .success(makeStream([folder])))

        // ViewModel 데이터 업데이트
        sut.viewModel.updateRecentCategory()
        sut.viewModel.updateMyFolderCategory()

        // 비동기 업데이트 대기
        try? await Task.sleep(nanoseconds: 300_000_000)

        // When
        sut.viewModel.pushSearchView()

        // Then
        XCTAssertTrue(sut.mockCoordinator.pushSearchViewCalled)
        XCTAssertEqual(sut.mockCoordinator.pushedSearchType, .main)
        XCTAssertEqual(sut.mockCoordinator.pushedSearchItems.count, 2)

        let hasNote = sut.mockCoordinator.pushedSearchItems.contains { item in
            if case .voiceNote(let n) = item { return n.id == note.id }
            return false
        }
        let hasFolder = sut.mockCoordinator.pushedSearchItems.contains { item in
            if case .folder(let f) = item { return f.id == folder.id }
            return false
        }

        XCTAssertTrue(hasNote)
        XCTAssertTrue(hasFolder)
    }

    func test_didScroll_상태변경() {
        let sut = makeSUT()

        sut.viewModel.setDidScroll(true)
        XCTAssertTrue(sut.viewModel.didScroll)

        sut.viewModel.setDidScroll(false)
        XCTAssertFalse(sut.viewModel.didScroll)
    }

    func test_handleRecordButtonTap_권한허용_바로녹음화면이동() async {
        let sut = makeSUT()
        await sut.mockVoiceRecordRepo.setCheckPermissionResult(.authorized)
        await sut.mockVoiceRecordRepo.expectCheckPermission(callCount: 1)

        var alertActionCalled = false
        sut.viewModel.handleRecordButtonTap(alertAction: { alertActionCalled = true })

        await sut.mockVoiceRecordRepo.verify()
        XCTAssertTrue(sut.mockCoordinator.presentRecodingViewCalled)
        XCTAssertFalse(alertActionCalled)
    }

    func test_handleRecordButtonTap_권한거부_알럿노출() async {
        let sut = makeSUT()
        await sut.mockVoiceRecordRepo.setCheckPermissionResult(.denied)
        await sut.mockVoiceRecordRepo.expectCheckPermission(callCount: 1)

        var alertActionCalled = false
        sut.viewModel.handleRecordButtonTap(alertAction: { alertActionCalled = true })

        await sut.mockVoiceRecordRepo.verify()
        XCTAssertFalse(sut.mockCoordinator.presentRecodingViewCalled)
        XCTAssertTrue(alertActionCalled)
    }

    func test_handleRecordButtonTap_권한미결정_알럿노출() async {
        let sut = makeSUT()
        await sut.mockVoiceRecordRepo.setCheckPermissionResult(.notDetermined)
        await sut.mockVoiceRecordRepo.expectCheckPermission(callCount: 1)

        var alertActionCalled = false
        sut.viewModel.handleRecordButtonTap(alertAction: { alertActionCalled = true })

        await sut.mockVoiceRecordRepo.verify()
        XCTAssertFalse(sut.mockCoordinator.presentRecodingViewCalled)
        XCTAssertTrue(alertActionCalled)
    }

    // MARK: - Update Tests

    func test_updateVoiceNoteCategory_호출시_기본폴더보이스노트로드확인() async {
        // Given
        let sut = makeSUT()
        let defaultFolder = Folder.stub(name: "기본 폴더", kind: .default)
        let expectedNotes = [VoiceNote.stub(title: "노트1"), VoiceNote.stub(title: "노트2")]
        sut.mockFolderRepo.setFetchByKindResult(.default, result: .success([defaultFolder]))
        sut.mockVoiceNoteRepo.setObserveFolderResult(.success(makeStream(expectedNotes)))
        sut.mockVoiceNoteRepo.expectObserveFolder(callCount: 1, folderID: defaultFolder.id)

        // When
        sut.viewModel.updateVoiceNoteCategory()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        sut.mockVoiceNoteRepo.verify()
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
        sut.mockVoiceNoteRepo.setObserveRecentResult(.success(makeStream(expectedNotes)))
        sut.mockVoiceNoteRepo.expectObserveRecent(callCount: 1)

        // When
        sut.viewModel.updateRecentCategory()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        sut.mockVoiceNoteRepo.verify()
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
            Folder(name: "테스트 폴더 1", kind: .custom),
            Folder(name: "테스트 폴더 2", kind: .custom)
        ]

        sut.mockFolderRepo.setObserveByKindResult(.custom, result: .success(makeStream(expectedFolders)))

        sut.viewModel.updateMyFolderCategory()

        // Task 내부 비동기 대기
        try? await Task.sleep(nanoseconds: 300_000_000)

        sut.mockFolderRepo.verify()
        XCTAssertEqual(sut.viewModel.categoryData[2].items.count, 2)

        if case .folder(let folder) = sut.viewModel.categoryData[2].items[0] {
            XCTAssertEqual(folder.name, "테스트 폴더 1")
        } else {
            XCTFail("Folder 타입이 아닙니다.")
        }
    }

    func test_updateTrashCategory_호출시_데이터로드확인() async {
        let sut = makeSUT()
        let trashedNote = VoiceNote.stub(title: "삭제된 노트")

        sut.mockFolderRepo.setObserveTrashedResult(.success(makeStream([])))
        sut.mockVoiceNoteRepo.setObserveTrashedResult(.success(makeStream([trashedNote])))

        sut.viewModel.updateTrashCategory()

        try? await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(sut.viewModel.categoryData[3].items.count, 1)
        if case .voiceNote(let note) = sut.viewModel.categoryData[3].items[0] {
            XCTAssertEqual(note.title, "삭제된 노트")
        } else {
            XCTFail("VoiceNote 타입이 아닙니다.")
        }
    }
}
