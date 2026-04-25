@testable import Presentation
import Domain
import DomainTesting
import XCTest

@MainActor
final class MockFolderCoordinatorDelegate: FolderCoordinatorDelegate {
    var popCalled = false
    var pushedFolder: Folder?

    func pop() {
        popCalled = true
    }

    func pushMyFolderDetailView(_ folder: Folder) {
        pushedFolder = folder
    }
}

@MainActor
final class FolderViewModelTests: XCTestCase {
    // MARK: - SUT

    private struct SUT {
        let viewModel: FolderViewModel
        let mockFolderRepo: MockFolderRepository
        let mockCoordinator: MockFolderCoordinatorDelegate
    }

    private func makeSUT(initialItems: [ContentItem] = []) -> SUT {
        let mockFolderRepo = MockFolderRepository()
        let mockCoordinator = MockFolderCoordinatorDelegate()

        let initialCategory = CategoryToggle(
            imageName: "folder",
            title: "개인 폴더",
            items: initialItems
        )

        let viewModel = FolderViewModel(
            category: initialCategory,
            folderUseCase: DefaultFolderUseCase(repository: mockFolderRepo)
        )
        viewModel.coordinator = mockCoordinator

        return SUT(
            viewModel: viewModel,
            mockFolderRepo: mockFolderRepo,
            mockCoordinator: mockCoordinator
        )
    }

    // MARK: - Initial State Tests

    func test_초기상태_확인() {
        let sut = makeSUT()

        XCTAssertEqual(sut.viewModel.category.title, "개인 폴더")
        XCTAssertFalse(sut.viewModel.showTextField)
        XCTAssertNil(sut.viewModel.editFolder)
    }

    // MARK: - UI Action Tests

    func test_didTapBack_호출시_Pop() {
        let sut = makeSUT()

        sut.viewModel.didTapBack()

        XCTAssertTrue(sut.mockCoordinator.popCalled)
    }

    func test_pushDetail_호출시_화면전환() {
        let sut = makeSUT()
        let folder = Folder(name: "테스트")

        sut.viewModel.pushDetail(folder)

        XCTAssertEqual(sut.mockCoordinator.pushedFolder?.id, folder.id)
    }

    func test_openTextFieldView_호출시_상태변경() {
        let sut = makeSUT()
        let folder = Folder(name: "수정 폴더")

        sut.viewModel.openTextField(for: folder)

        XCTAssertTrue(sut.viewModel.showTextField)
        XCTAssertEqual(sut.viewModel.editFolder?.name, "수정 폴더")
    }

    func test_closeTextFieldView_호출시_상태초기화() {
        let sut = makeSUT()
        sut.viewModel.openTextField()

        sut.viewModel.closeTextField()

        XCTAssertFalse(sut.viewModel.showTextField)
        XCTAssertNil(sut.viewModel.editFolder)
    }

    // MARK: - CRUD Tests

    func test_create_성공시_리스트에추가() async {
        let sut = makeSUT()
        let folderName = "신규 폴더"
        let createdFolder = Folder(name: folderName)

        sut.mockFolderRepo.setCreateResult(.success(createdFolder))
        sut.mockFolderRepo.expectCreate(name: folderName, callCount: 1)

        sut.viewModel.create(name: folderName)

        // Task 대기
        try? await Task.sleep(nanoseconds: 300_000_000)

        sut.mockFolderRepo.verify()
        XCTAssertEqual(sut.viewModel.category.items.count, 1)
        XCTAssertFalse(sut.viewModel.showTextField)
    }

    func test_fetchAll_정상로드() async {
        let sut = makeSUT()
        let expectedFolders = [
            Folder(name: "새 폴더 1", kind: .custom),
            Folder(name: "기본 폴더", kind: .default), // isDeletable = false는 제외되어야 함
            Folder(name: "새 폴더 2", kind: .custom)
        ]

        sut.mockFolderRepo.setFetchAllResult(.success(expectedFolders))
        sut.mockFolderRepo.expectFetchAll(callCount: 1)

        sut.viewModel.fetchAll()

        try? await Task.sleep(nanoseconds: 300_000_000)

        sut.mockFolderRepo.verify()
        XCTAssertEqual(sut.viewModel.category.items.count, 2)
    }

    func test_move_성공시_리스트에서제거() async {
        let folder = Folder(name: "이동 폴더")
        let trash = Folder.stub(kind: .trash)
        let sut = makeSUT(initialItems: [.folder(folder)])

        sut.mockFolderRepo.setFetchByKindResult(.trash, result: .success([trash]))
        sut.mockFolderRepo.setFetchByIDResult(.success(folder))
        sut.mockFolderRepo.setUpdateResult(.success(folder))
        sut.mockFolderRepo.expectUpdate(folderID: folder.id, callCount: 1)

        sut.viewModel.move(folder: folder)
        try? await Task.sleep(nanoseconds: 300_000_000)

        sut.mockFolderRepo.verify()
        XCTAssertTrue(sut.viewModel.category.items.isEmpty)
    }

    func test_update_성공시_리스트항목교체() async {
        let initialFolder = Folder(id: UUID(), name: "원본 폴더")
        let sut = makeSUT(initialItems: [ContentItem.folder(initialFolder)])

        let newName = "수정된 폴더"
        let updatedFolder = Folder(
            id: initialFolder.id,
            name: newName,
            createdAt: initialFolder.createdAt,
            voiceNoteIDs: initialFolder.voiceNoteIDs,
            kind: initialFolder.kind,
            deletedAt: initialFolder.deletedAt
        )

        sut.mockFolderRepo.setUpdateResult(.success(updatedFolder))
        sut.mockFolderRepo.expectUpdate(folderID: initialFolder.id, callCount: 1)

        // 수정 모드 진입
        sut.viewModel.openTextField(for: initialFolder)

        sut.viewModel.update(name: newName)

        // Task 대기
        try? await Task.sleep(nanoseconds: 300_000_000)

        sut.mockFolderRepo.verify()

        if case .folder(let folder) = sut.viewModel.category.items[0] {
            XCTAssertEqual(folder.name, newName)
            XCTAssertEqual(folder.id, initialFolder.id)
        } else {
            XCTFail("Folder 타입이 아닙니다.")
        }

        XCTAssertNil(sut.viewModel.editFolder)
        XCTAssertFalse(sut.viewModel.showTextField)
    }
}
