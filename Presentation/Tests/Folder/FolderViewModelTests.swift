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
        let mockWasteBasketRepo: MockWasteBasketRepository
        let mockCoordinator: MockFolderCoordinatorDelegate
    }

    private func makeSUT(initialItems: [Presentation.LibraryItem] = []) -> SUT {
        let mockFolderRepo = MockFolderRepository()
        let mockWasteBasketRepo = MockWasteBasketRepository()
        let mockCoordinator = MockFolderCoordinatorDelegate()

        let initialCategory = CategoryToggle(
            imageName: "folder",
            title: "개인 폴더",
            items: initialItems
        )

        let viewModel = FolderViewModel(
            category: initialCategory,
            createUseCase: DefaultCreateFolderUseCase(repository: mockFolderRepo),
            updateUseCase: DefaultUpdateFolderUseCase(repository: mockFolderRepo),
            wasteBasketRepository: mockWasteBasketRepo
        )
        viewModel.coordinator = mockCoordinator

        return SUT(
            viewModel: viewModel,
            mockFolderRepo: mockFolderRepo,
            mockWasteBasketRepo: mockWasteBasketRepo,
            mockCoordinator: mockCoordinator
        )
    }

    // MARK: - Initial State Tests

    func test_초기상태_확인() {
        let sut = makeSUT()

        XCTAssertEqual(sut.viewModel.category.title, "개인 폴더")
        XCTAssertFalse(sut.viewModel.showAlert)
        XCTAssertNil(sut.viewModel.editFolder)
    }

    // MARK: - UI Action Tests

    func test_didTapBack_호출시_Pop() {
        let sut = makeSUT()

        sut.viewModel.didTapBack()

        XCTAssertTrue(sut.mockCoordinator.popCalled)
    }

    func test_openTextFieldView_호출시_상태변경() {
        let sut = makeSUT()
        let folder = Folder(name: "수정 폴더")

        sut.viewModel.openTextFieldView(for: folder)

        XCTAssertTrue(sut.viewModel.showAlert)
        XCTAssertEqual(sut.viewModel.editFolder?.name, "수정 폴더")
    }

    func test_closeTextFieldView_호출시_상태초기화() {
        let sut = makeSUT()
        sut.viewModel.openTextFieldView()

        sut.viewModel.closeTextFieldView()

        XCTAssertFalse(sut.viewModel.showAlert)
        XCTAssertNil(sut.viewModel.editFolder)
    }

    // MARK: - CRUD Tests

    func test_create_성공시_리스트에추가() async {
        let sut = makeSUT()
        let folderName = "신규 폴더"
        let createdFolder = Folder(name: folderName)

        await sut.mockFolderRepo.setCreateResult(.success(createdFolder))
        await sut.mockFolderRepo.expectCreate(name: folderName, callCount: 1)

        sut.viewModel.create(name: folderName)

        // Task 대기
        try? await Task.sleep(nanoseconds: 300_000_000)

        await sut.mockFolderRepo.verify()
        XCTAssertEqual(sut.viewModel.category.items.count, 1)
        XCTAssertFalse(sut.viewModel.showAlert)
    }

    func test_move_성공시_리스트에서제거() async {
        let folder = Folder(name: "이동 폴더")
        let sut = makeSUT(initialItems: [.folder(folder)])

        await sut.mockWasteBasketRepo.setMoveResult(.success(()))
        await sut.mockWasteBasketRepo.expectMoveToWasteBasket(
            item: .folder(obj: folder), callCount: 1
        )

        sut.viewModel.move(folder: folder)
        try? await Task.sleep(nanoseconds: 300_000_000)

        await sut.mockWasteBasketRepo.verify()
        XCTAssertTrue(sut.viewModel.category.items.isEmpty)
    }

    func test_update_성공시_리스트항목교체() async {
        let initialFolder = Folder(id: UUID(), name: "원본 폴더")
        let sut = makeSUT(initialItems: [Presentation.LibraryItem.folder(initialFolder)])

        let newName = "수정된 폴더"
        let updatedFolder = Folder(
            id: initialFolder.id,
            name: newName,
            createdAt: initialFolder.createdAt,
            content: initialFolder.content,
            isDeletable: initialFolder.isDeletable,
            deletedAt: initialFolder.deletedAt
        )

        await sut.mockFolderRepo.setUpdateResult(.success(updatedFolder))
        await sut.mockFolderRepo.expectUpdate(folderID: initialFolder.id, callCount: 1)

        // 수정 모드 진입
        sut.viewModel.openTextFieldView(for: initialFolder)

        sut.viewModel.update(name: newName)

        // Task 대기
        try? await Task.sleep(nanoseconds: 300_000_000)

        await sut.mockFolderRepo.verify()

        if case .folder(let folder) = sut.viewModel.category.items[0] {
            XCTAssertEqual(folder.name, newName)
            XCTAssertEqual(folder.id, initialFolder.id)
        } else {
            XCTFail("Folder 타입이 아닙니다.")
        }

        XCTAssertNil(sut.viewModel.editFolder)
        XCTAssertFalse(sut.viewModel.showAlert)
    }
}
