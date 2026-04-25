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
        let mockFolderRepo: MockFolderRepository
        let mockVoiceNoteRepo: MockVoiceNoteRepository
        let mockCoordinator: MockTrashCoordinatorDelegate
    }

    private func makeSUT() -> SUT {
        let mockFolderRepo = MockFolderRepository()
        let mockVoiceNoteRepo = MockVoiceNoteRepository()
        let mockCoordinator = MockTrashCoordinatorDelegate()

        let viewModel = TrashViewModel(
            folderUseCase: DefaultFolderUseCase(repository: mockFolderRepo),
            voiceNoteUseCase: DefaultVoiceNoteUseCase(
                repository: mockVoiceNoteRepo,
                folderRepository: mockFolderRepo,
                analysisService: MockVoiceNoteAnalysisService()
            )
        )
        viewModel.coordinator = mockCoordinator

        return SUT(
            viewModel: viewModel,
            mockFolderRepo: mockFolderRepo,
            mockVoiceNoteRepo: mockVoiceNoteRepo,
            mockCoordinator: mockCoordinator
        )
    }

    private func setTrashStreams(
        _ sut: SUT,
        items: [ContentItem]
    ) {
        var folders: [Folder] = []
        var notes: [VoiceNote] = []
        for item in items {
            switch item {
            case .folder(let folder): folders.append(folder)
            case .voiceNote(let note): notes.append(note)
            }
        }
        sut.mockFolderRepo.setObserveTrashedResult(.success(makeStream(folders)))
        sut.mockVoiceNoteRepo.setObserveTrashedResult(.success(makeStream(notes)))
    }

    private func makeStream<T: Sendable>(_ value: T) -> AsyncStream<T> {
        AsyncStream { continuation in
            continuation.yield(value)
            continuation.finish()
        }
    }

    // MARK: - Initial State Tests

    func test_초기상태_확인() {
        let sut = makeSUT()

        XCTAssertTrue(sut.viewModel.items.isEmpty, "초기 항목 배열은 비어있어야 합니다.")
        XCTAssertNil(sut.viewModel.errorMessage, "초기 에러 메시지는 없어야 합니다.")
        XCTAssertFalse(sut.viewModel.showTrashAlert, "초기 경고창 상태는 false여야 합니다.")
    }

    func test_openTrashAlert_상태변경() {
        let sut = makeSUT()
        XCTAssertFalse(sut.viewModel.showTrashAlert)

        sut.viewModel.openTrashAlert()

        XCTAssertTrue(sut.viewModel.showTrashAlert, "알럿 상태가 true가 되어야 합니다.")
    }

    func test_didTapBack_코디네이터pop호출() {
        let sut = makeSUT()
        XCTAssertFalse(sut.mockCoordinator.popCalled)

        sut.viewModel.didTapBack()

        XCTAssertTrue(sut.mockCoordinator.popCalled, "뒤로가기 시 pop이 정상 호출되어야 합니다.")
    }

    // MARK: - Update & Fetch Tests

    func test_fetchItems_정상적으로_가져오기() async {
        let sut = makeSUT()
        let fetchResult: [ContentItem] = [
            .folder(Folder(name: "테스트 폴더")),
            .voiceNote(VoiceNote(
                title: "테스트 노트",
                folderID: UUID(),
                voiceRecord: VoiceRecord(audioFilePath: "VoiceRecords/null.m4a", duration: 10),
                analysisState: .pending
            ))
        ]

        setTrashStreams(sut, items: fetchResult)

        sut.viewModel.onAppear()
        try? await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(sut.viewModel.items.count, 2, "2개의 항목을 정상적으로 불러와야 합니다.")
    }

    func test_fetchItems_정렬_확인() async {
        let sut = makeSUT()
        let now = Date()
        let items: [ContentItem] = [
            .folder(Folder(name: "오래된 삭제", deletedAt: now.addingTimeInterval(-1000))),
            .folder(Folder(name: "최근 삭제", deletedAt: now)),
            .folder(Folder(name: "중간 삭제", deletedAt: now.addingTimeInterval(-500)))
        ]
        setTrashStreams(sut, items: items)

        sut.viewModel.onAppear()
        try? await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(sut.viewModel.items.count, 3)
        XCTAssertEqual(sut.viewModel.items[0].deletedAt, now, "가장 최근 삭제된 항목이 첫 번째여야 합니다.")
        XCTAssertEqual(sut.viewModel.items[1].deletedAt, now.addingTimeInterval(-500))
        XCTAssertEqual(sut.viewModel.items[2].deletedAt, now.addingTimeInterval(-1000), "가장 오래된 삭제된 항목이 마지막이어야 합니다.")
    }

    // MARK: - Delete & Restore Tests

    func test_deleteAll_정상수행() async {
        let sut = makeSUT()
        let fetchResult: [ContentItem] = [
            .folder(Folder(name: "테스트 폴더"))
        ]
        setTrashStreams(sut, items: fetchResult)
        sut.mockFolderRepo.expectDelete(callCount: 1)

        sut.viewModel.onAppear()
        try? await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(sut.viewModel.items.count, 1)

        sut.viewModel.deleteAll()
        try? await Task.sleep(nanoseconds: 300_000_000)

        sut.mockFolderRepo.verify()
        XCTAssertTrue(sut.viewModel.items.isEmpty, "전체 삭제 진행 후 items 배열이 비워져야 합니다.")
    }

    func test_deleteItem_단일항목삭제() async {
        let sut = makeSUT()
        let folder = Folder(name: "삭제용 폴더")
        let item = ContentItem.folder(folder)
        setTrashStreams(sut, items: [item])
        sut.mockFolderRepo.expectDelete(callCount: 1)

        sut.viewModel.onAppear()
        try? await Task.sleep(nanoseconds: 300_000_000)

        sut.viewModel.delete(item: item)
        try? await Task.sleep(nanoseconds: 300_000_000)

        sut.mockFolderRepo.verify()
        XCTAssertTrue(sut.viewModel.items.isEmpty, "단일 삭제 진행 후 항목이 리스트에서 지워져야 합니다.")
    }

    func test_restoreItem_단일항목복구() async {
        let sut = makeSUT()
        let folder = Folder(name: "복구용 폴더", deletedAt: .now, parentID: UUID())
        let item = ContentItem.folder(folder)
        setTrashStreams(sut, items: [item])
        sut.mockFolderRepo.setFetchByIDResult(.success(folder))
        sut.mockFolderRepo.setUpdateResult(.success(folder))
        sut.mockFolderRepo.expectUpdate(folderID: folder.id, callCount: 1)

        sut.viewModel.onAppear()
        try? await Task.sleep(nanoseconds: 300_000_000)

        sut.viewModel.restore(item: item)
        try? await Task.sleep(nanoseconds: 300_000_000)

        sut.mockFolderRepo.verify()
        XCTAssertTrue(sut.viewModel.items.isEmpty, "복원 후 휴지통 목록에서 항목이 제거되어야 합니다.")
    }

    func test_cancelRestoreItem_단일항목복원취소() {
        let sut = makeSUT()
        let folder = Folder(name: "복원취소용 폴더")
        let trash = Folder.stub(kind: .trash)
        let item = ContentItem.folder(folder)
        sut.mockFolderRepo.setFetchByKindResult(.trash, result: .success([trash]))
        sut.mockFolderRepo.setFetchByIDResult(.success(folder))
        sut.mockFolderRepo.setUpdateResult(.success(folder))
        sut.mockFolderRepo.expectUpdate(folderID: folder.id, callCount: 1)

        sut.viewModel.cancelRestore(item: item)

        sut.mockFolderRepo.verify()
        XCTAssertEqual(sut.viewModel.items.count, 1, "복원 취소 후 항목이 다시 휴지통에 추가되어야 합니다.")
    }

    func test_cancelRestoreItems_복수항목복원취소() {
        let sut = makeSUT()
        let folder = Folder(name: "복원취소용 폴더 1")
        let voiceNote = VoiceNote(
            title: "복원취소용 노트 1",
            folderID: UUID(),
            voiceRecord: VoiceRecord(audioFilePath: "test.m4a", duration: 10),
            analysisState: .pending
        )
        let trash = Folder.stub(kind: .trash)
        let items = [
            ContentItem.folder(folder),
            ContentItem.voiceNote(voiceNote)
        ]
        sut.mockFolderRepo.setFetchByKindResult(.trash, result: .success([trash]))
        sut.mockFolderRepo.setFetchByIDResult(.success(folder))
        sut.mockFolderRepo.setUpdateResult(.success(folder))
        sut.mockVoiceNoteRepo.setFetchResult(.success(voiceNote))
        sut.mockVoiceNoteRepo.setUpdateResult(.success(voiceNote))

        sut.viewModel.cancelRestore(items: items)

        XCTAssertEqual(sut.viewModel.items.count, 2, "복원 취소 후 모든 항목이 다시 휴지통에 추가되어야 합니다.")
    }
}
