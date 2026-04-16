@testable import Presentation
import Domain
import DomainTesting
import XCTest

@MainActor
final class TrashViewModelTests: XCTestCase {
    // MARK: - SUT

    private struct SUT {
        let viewModel: TrashViewModel
        let mockRepo: MockWasteBasketRepository // Use single repo for all DefaultUseCases
        let mockCoordinator: MockBaseCoordinatorDelegate
    }

    private func makeSUT() -> SUT {
        let mockRepo = MockWasteBasketRepository()
        let mockCoordinator = MockBaseCoordinatorDelegate()

        let viewModel = TrashViewModel(
            repository: mockRepo
        )
        viewModel.coordinator = mockCoordinator

        return SUT(
            viewModel: viewModel,
            mockRepo: mockRepo,
            mockCoordinator: mockCoordinator
        )
    }

    // MARK: - Initial State Tests

    func test_초기상태_확인() {
        // Given & When
        let sut = makeSUT()

        // Then
        XCTAssertTrue(sut.viewModel.items.isEmpty, "초기 항목 배열은 비어있어야 합니다.")
        XCTAssertNil(sut.viewModel.errorMessage, "초기 에러 메시지는 없어야 합니다.")
        XCTAssertEqual(sut.viewModel.selectedOrder, .createdAt, "기본 정렬 순서는 생성일(.createdAt)이어야 합니다.")
        XCTAssertFalse(sut.viewModel.isSelectionMode, "초기 선택 모드는 false여야 합니다.")
        XCTAssertTrue(sut.viewModel.selectedItems.isEmpty, "선택된 아이템 초기 배열은 비어있어야 합니다.")
        XCTAssertFalse(sut.viewModel.showAlert, "초기 경고창 상태는 false여야 합니다.")
        XCTAssertTrue(sut.viewModel.isEmpty, "초기 isEmpty 속성은 true여야 합니다.")
    }

    // MARK: - Action Tests

    func test_toggleSelectionMode_토글확인_및_선택아이템초기화() {
        // Given
        let sut = makeSUT()
        let dummyItem = WasteBasketItem.folder(
            obj: Folder(name: "테스트 폴더", createdAt: Date().addingTimeInterval(-86400 * 5))
        )
        sut.viewModel.toggleSelectionMode() // isSelectionMode = true
        XCTAssertTrue(sut.viewModel.isSelectionMode, "토글 후 true가 되어야 합니다.")

        sut.viewModel.selectItem(dummyItem)
        XCTAssertEqual(sut.viewModel.selectedItems.count, 1, "선택 시 배열에 추가되어야 합니다.")

        // When
        sut.viewModel.toggleSelectionMode() // isSelectionMode = false

        // Then
        XCTAssertFalse(sut.viewModel.isSelectionMode, "다시 토글 후 false가 되어야 합니다.")
        XCTAssertTrue(sut.viewModel.selectedItems.isEmpty, "선택 모드 해제 시 선택된 아이템 배열이 초기화되어야 합니다.")
    }

    func test_touchCreatedAction_정렬방식변경() {
        // Given
        let sut = makeSUT()
        sut.viewModel.touchUpdatedAction() // 일단 강제로 수정일 순으로 변경

        // When
        sut.viewModel.touchCreatedAction()

        // Then
        XCTAssertEqual(sut.viewModel.selectedOrder, .createdAt, "선택된 정렬 방식이 생성일(.createdAt) 순이어야 합니다.")
    }

    func test_touchUpdatedAction_정렬방식변경() {
        // Given
        let sut = makeSUT()

        // When
        sut.viewModel.touchUpdatedAction()

        // Then
        XCTAssertEqual(sut.viewModel.selectedOrder, .updatedAt, "선택된 정렬 방식이 수정일(.updatedAt) 순이어야 합니다.")
    }

    func test_toggleShowAlert_상태토글() {
        // Given
        let sut = makeSUT()
        XCTAssertFalse(sut.viewModel.showAlert)

        // When
        sut.viewModel.toggleShowAlert()

        // Then
        XCTAssertTrue(sut.viewModel.showAlert, "알럿 상태가 true가 되어야 합니다.")
    }

    func test_didTapBack_코디네이터pop호출() {
        // Given
        let sut = makeSUT()
        XCTAssertFalse(sut.mockCoordinator.popCalled)

        // When
        sut.viewModel.didTapBack()

        // Then
        XCTAssertTrue(sut.mockCoordinator.popCalled, "뒤로가기 시 pop이 정상 호출되어야 합니다.")
    }

    // MARK: - Update & Fetch Tests

    func test_fetchItems_정상적으로_가져오기() async {
        // Given
        let sut = makeSUT()
        let fetchResult: [WasteBasketItem] = [
            .folder(obj: Folder(name: "테스트 폴더")),
            .voiceNote(obj: VoiceNote(
                title: "테스트 노트",
                folderID: UUID(),
                voiceRecord: VoiceRecord(audioFilePath: "VoiceRecords/null.m4a", duration: 10)
            ))
        ]

        await sut.mockRepo.setFetchAllResult(.success(fetchResult))
        await sut.mockRepo.expectFetchAll(callCount: 1)

        // When
        sut.viewModel.fetchItems()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        await sut.mockRepo.verify()
        XCTAssertEqual(sut.viewModel.items.count, 2, "2개의 항목을 정상적으로 불러와야 합니다.")
    }

    // MARK: - Delete & Restore Tests

    func test_deleteAll_정상수행() async {
        // Given
        let sut = makeSUT()
        let fetchResult: [WasteBasketItem] = [
            .folder(obj: Folder(name: "테스트 폴더"))
        ]
        await sut.mockRepo.setFetchAllResult(.success(fetchResult))
        await sut.mockRepo.setDeleteResult(.success(()))
        await sut.mockRepo.expectAllClear(callCount: 1)

        sut.viewModel.fetchItems()
        try? await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(sut.viewModel.items.count, 1)

        // When
        sut.viewModel.deleteAll()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        await sut.mockRepo.verify()
        XCTAssertTrue(sut.viewModel.items.isEmpty, "전체 삭제 진행 후 items 배열이 비워져야 합니다.")
    }

    func test_deleteItem_단일항목삭제() async {
        // Given
        let sut = makeSUT()
        let item = WasteBasketItem.folder(obj: Folder(name: "삭제용 폴더"))
        await sut.mockRepo.setFetchAllResult(.success([item]))
        await sut.mockRepo.setDeleteResult(.success(()))
        await sut.mockRepo.expectDelete(item: item, callCount: 1)

        sut.viewModel.fetchItems()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // When
        sut.viewModel.delete(item: item)
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        await sut.mockRepo.verify()
        XCTAssertTrue(sut.viewModel.items.isEmpty, "단일 삭제 진행 후 항목이 리스트에서 지워져야 합니다.")
    }

    func test_restoreItem_단일항목복구() async {
        // Given
        let sut = makeSUT()
        let item = WasteBasketItem.folder(obj: Folder(name: "복구용 폴더"))
        await sut.mockRepo.setFetchAllResult(.success([item]))
        await sut.mockRepo.setRestoreResult(.success(()))
        await sut.mockRepo.expectRestore(item: item, callCount: 1)

        sut.viewModel.fetchItems()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // When
        sut.viewModel.restore(item: item)
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        await sut.mockRepo.verify()
        XCTAssertTrue(sut.viewModel.items.isEmpty, "복원 후 휴지통 목록에서 항목이 제거되어야 합니다.")
    }
}
