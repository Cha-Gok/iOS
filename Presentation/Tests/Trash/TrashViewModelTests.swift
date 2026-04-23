@testable import Presentation
import Domain
import DomainTesting
import XCTest

@MainActor
final class MockTrashCoordinatorDelegate: TrashCoordinatorDelegate {
    var popCalled = false
    var pushedVoiceNote: VoiceNote?
    var pushedFolder: Folder?

    func pop() {
        popCalled = true
    }

    func pushVoiceNoteView(voiceNote: VoiceNote) {
        pushedVoiceNote = voiceNote
    }

    func pushMyFolderDetailView(_ folder: Folder) {
        pushedFolder = folder
    }
}

@MainActor
final class TrashViewModelTests: XCTestCase {
    // MARK: - SUT

    private struct SUT {
        let viewModel: TrashViewModel
        let mockRepo: MockWasteBasketRepository // Use single repo for all DefaultUseCases
        let mockCoordinator: MockTrashCoordinatorDelegate
    }

    private func makeSUT() -> SUT {
        let mockRepo = MockWasteBasketRepository()
        let mockCoordinator = MockTrashCoordinatorDelegate()

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
        XCTAssertFalse(sut.viewModel.showTrashAlert, "초기 경고창 상태는 false여야 합니다.")
    }

    func test_openTrashAlert_상태변경() {
        // Given
        let sut = makeSUT()
        XCTAssertFalse(sut.viewModel.showTrashAlert)

        // When
        sut.viewModel.openTrashAlert()

        // Then
        XCTAssertTrue(sut.viewModel.showTrashAlert, "알럿 상태가 true가 되어야 합니다.")
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
                voiceRecord: VoiceRecord(audioFilePath: "VoiceRecords/null.m4a", duration: 10),
                analysisState: .pending
            ))
        ]

        sut.mockRepo.setFetchAllResult(.success(fetchResult))
        sut.mockRepo.expectFetchAll(callCount: 1)

        // When
        sut.viewModel.fetchItems()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        sut.mockRepo.verify()
        XCTAssertEqual(sut.viewModel.items.count, 2, "2개의 항목을 정상적으로 불러와야 합니다.")
    }

    func test_fetchItems_정렬_확인() async {
        // Given
        let sut = makeSUT()
        let now = Date()
        let items: [WasteBasketItem] = [
            .folder(obj: Folder(name: "오래된 삭제", deletedAt: now.addingTimeInterval(-1000))),
            .folder(obj: Folder(name: "최근 삭제", deletedAt: now)),
            .folder(obj: Folder(name: "중간 삭제", deletedAt: now.addingTimeInterval(-500)))
        ]
        sut.mockRepo.setFetchAllResult(.success(items))

        // When
        sut.viewModel.fetchItems()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        XCTAssertEqual(sut.viewModel.items.count, 3)
        XCTAssertEqual(sut.viewModel.items[0].deletedAt, now, "가장 최근 삭제된 항목이 첫 번째여야 합니다.")
        XCTAssertEqual(sut.viewModel.items[1].deletedAt, now.addingTimeInterval(-500))
        XCTAssertEqual(sut.viewModel.items[2].deletedAt, now.addingTimeInterval(-1000), "가장 오래된 삭제된 항목이 마지막이어야 합니다.")
    }

    // MARK: - Delete & Restore Tests

    func test_deleteAll_정상수행() async {
        // Given
        let sut = makeSUT()
        let fetchResult: [WasteBasketItem] = [
            .folder(obj: Folder(name: "테스트 폴더"))
        ]
        sut.mockRepo.setFetchAllResult(.success(fetchResult))
        sut.mockRepo.setDeleteResult(.success(()))
        sut.mockRepo.expectAllClear(callCount: 1)

        sut.viewModel.fetchItems()
        try? await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(sut.viewModel.items.count, 1)

        // When
        sut.viewModel.deleteAll()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        sut.mockRepo.verify()
        XCTAssertTrue(sut.viewModel.items.isEmpty, "전체 삭제 진행 후 items 배열이 비워져야 합니다.")
    }

    func test_deleteItem_단일항목삭제() async {
        // Given
        let sut = makeSUT()
        let item = WasteBasketItem.folder(obj: Folder(name: "삭제용 폴더"))
        sut.mockRepo.setFetchAllResult(.success([item]))
        sut.mockRepo.setDeleteResult(.success(()))
        sut.mockRepo.expectDelete(item: item, callCount: 1)

        sut.viewModel.fetchItems()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // When
        sut.viewModel.delete(item: item)
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        sut.mockRepo.verify()
        XCTAssertTrue(sut.viewModel.items.isEmpty, "단일 삭제 진행 후 항목이 리스트에서 지워져야 합니다.")
    }

    func test_restoreItem_단일항목복구() async {
        // Given
        let sut = makeSUT()
        let item = WasteBasketItem.folder(obj: Folder(name: "복구용 폴더"))
        sut.mockRepo.setFetchAllResult(.success([item]))
        sut.mockRepo.setRestoreResult(.success(()))
        sut.mockRepo.expectRestore(item: item, callCount: 1)

        sut.viewModel.fetchItems()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // When
        sut.viewModel.restore(item: item)
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        sut.mockRepo.verify()
        XCTAssertTrue(sut.viewModel.items.isEmpty, "복원 후 휴지통 목록에서 항목이 제거되어야 합니다.")
    }

    func test_cancelRestoreItem_단일항목복원취소() {
        // Given
        let sut = makeSUT()
        let item = WasteBasketItem.folder(obj: Folder(name: "복원취소용 폴더"))
        sut.mockRepo.setMoveResult(.success(()))
        sut.mockRepo.expectMoveToWasteBasket(item: item, callCount: 1)

        // When
        sut.viewModel.cancelRestore(item: item)

        // Then
        sut.mockRepo.verify()
        XCTAssertEqual(sut.viewModel.items.count, 1, "복원 취소 후 항목이 다시 휴지통에 추가되어야 합니다.")
    }

    func test_cancelRestoreItems_복수항목복원취소() {
        // Given
        let sut = makeSUT()
        let items = [
            WasteBasketItem.folder(obj: Folder(name: "복원취소용 폴더 1")),
            WasteBasketItem.voiceNote(obj: VoiceNote(
                title: "복원취소용 노트 1",
                folderID: UUID(),
                voiceRecord: VoiceRecord(audioFilePath: "test.m4a", duration: 10),
                analysisState: .pending
            ))
        ]
        sut.mockRepo.setMoveResult(.success(()))
        sut.mockRepo.expectMoveAllToWasteBasket(items: items, callCount: 1)

        // When
        sut.viewModel.cancelRestore(items: items)

        // Then
        sut.mockRepo.verify()
        XCTAssertEqual(sut.viewModel.items.count, 2, "복원 취소 후 모든 항목이 다시 휴지통에 추가되어야 합니다.")
    }
}
