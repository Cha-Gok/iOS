@testable import Presentation
import Domain
import DomainTesting
import XCTest

@MainActor
final class MockFolderDetailCoordinatorDelegate: FolderDetailCoordinatorDelegate {
    var popCalled = false
    var pushedVoiceNote: VoiceNote?
    var pushSearchViewCalled = false
    var pushedSearchType: SearchViewModel.SearchType?
    var pushedSearchItems: [ContentItem] = []

    var presentFolderListCalled = false

    func pop() {
        popCalled = true
    }

    func pushVoiceNoteView(voiceNote: Domain.VoiceNote) {
        pushedVoiceNote = voiceNote
    }

    func presentFolderList(with voiceNotes: [VoiceNote], onComplete: ((String) -> Void)?) {
        presentFolderListCalled = true
    }

    func pushSearchView(type: SearchViewModel.SearchType, items: [ContentItem]) {
        pushSearchViewCalled = true
        pushedSearchType = type
        pushedSearchItems = items
    }
}

@MainActor
final class FolderDetailViewModelTests: XCTestCase {
    // MARK: - SUT

    private struct SUT {
        let viewModel: FolderDetailViewModel
        let mockVoiceNoteRepo: MockVoiceNoteRepository
        let mockFolderRepo: MockFolderRepository
        let mockCoordinator: MockFolderDetailCoordinatorDelegate
        let testFolderID: UUID
    }

    private func makeSUT(title: String = "상세 폴더", folderID: UUID = UUID()) -> SUT {
        let mockVoiceNoteRepo = MockVoiceNoteRepository()
        let mockFolderRepo = MockFolderRepository()
        let mockCoordinator = MockFolderDetailCoordinatorDelegate()

        let viewModel = FolderDetailViewModel(
            title: title,
            folderID: folderID,
            voiceNoteUseCase: DefaultVoiceNoteUseCase(
                repository: mockVoiceNoteRepo,
                folderRepository: mockFolderRepo,
                analysisService: MockVoiceNoteAnalysisService()
            )
        )
        viewModel.coordinator = mockCoordinator

        return SUT(
            viewModel: viewModel,
            mockVoiceNoteRepo: mockVoiceNoteRepo,
            mockFolderRepo: mockFolderRepo,
            mockCoordinator: mockCoordinator,
            testFolderID: folderID
        )
    }

    private func makeStream(_ items: [VoiceNote]) -> AsyncStream<[VoiceNote]> {
        AsyncStream { continuation in
            continuation.yield(items)
            continuation.finish()
        }
    }

    // MARK: - Initial State Tests

    func test_초기상태_확인() {
        let folderID = UUID()
        let sut = makeSUT(title: "테스트 폴더", folderID: folderID)

        XCTAssertEqual(sut.viewModel.title, "테스트 폴더")
        XCTAssertEqual(sut.viewModel.folderID, folderID)
        XCTAssertTrue(sut.viewModel.items.isEmpty)
        XCTAssertEqual(sut.viewModel.select, .none)
    }

    // MARK: - UI Action Tests

    func test_didTapBack_호출시_Pop() {
        let sut = makeSUT()

        sut.viewModel.didTapBack()

        XCTAssertTrue(sut.mockCoordinator.popCalled)
    }

    func test_pushVoiceNote_호출시_화면전환() {
        let sut = makeSUT()
        let note = VoiceNote.stub(title: "테스트 노트")

        sut.viewModel.pushVoiceNote(voiceNote: note)

        XCTAssertEqual(sut.mockCoordinator.pushedVoiceNote?.id, note.id)
    }

    func test_pushSearch_호출시_화면전환() async {
        let sut = makeSUT(title: "상세 폴더")
        let note = VoiceNote.stub(title: "검색용 노트")

        sut.mockVoiceNoteRepo.setObserveFolderResult(.success(makeStream([note])))
        sut.viewModel.onAppear()
        try? await Task.sleep(nanoseconds: 300_000_000)

        sut.viewModel.pushSearch()

        XCTAssertTrue(sut.mockCoordinator.pushSearchViewCalled)
        if case .myDetailFolder(let title) = sut.mockCoordinator.pushedSearchType {
            XCTAssertEqual(title, "상세 폴더")
        } else {
            XCTFail("Wrong search type")
        }
        XCTAssertEqual(sut.mockCoordinator.pushedSearchItems.count, 1)
    }

    func test_presentMoveFolder_버튼탭시_선택항목존재하면_시트오픈() {
        let sut = makeSUT()
        let note = VoiceNote.stub(title: "테스트 노트")

        sut.viewModel.selectItem(note)
        sut.viewModel.presentMoveFolder { _ in }

        XCTAssertTrue(sut.mockCoordinator.presentFolderListCalled)
    }

    func test_presentMoveFolder_버튼탭시_선택항목없으면_무시() {
        let sut = makeSUT()

        sut.viewModel.presentMoveFolder { _ in }

        XCTAssertFalse(sut.mockCoordinator.presentFolderListCalled)
    }

    func test_AlertView_상태변경() {
        let sut = makeSUT()
        let note = VoiceNote.stub(title: "테스트 노트")

        // 아이템이 선택된 상태여야 얼럿이 열림
        sut.viewModel.selectItem(note)
        sut.viewModel.openAlertView()
        XCTAssertTrue(sut.viewModel.showAlert)

        sut.viewModel.closeAlertView()
        XCTAssertFalse(sut.viewModel.showAlert)
    }

    func test_openAlertView_아이템선택없을시_상태원복() {
        let sut = makeSUT()

        // 선택 모드이지만 아이템은 없는 상태
        sut.viewModel.setSelectionMode(.multiple)
        XCTAssertEqual(sut.viewModel.select, .multiple)

        // 아이템 없이 얼럿 오픈 시도
        sut.viewModel.openAlertView()

        // 얼럿은 열리지 않고 선택 모드도 해제되어야 함
        XCTAssertFalse(sut.viewModel.showAlert)
        XCTAssertEqual(sut.viewModel.select, .none)
    }

    func test_fetchItems_호출시_보이스노트로드확인() async {
        let sut = makeSUT()
        let expectedNotes = [
            VoiceNote.stub(title: "노트1"),
            VoiceNote.stub(title: "노트2")
        ]

        sut.mockVoiceNoteRepo.setObserveFolderResult(.success(makeStream(expectedNotes)))
        sut.mockVoiceNoteRepo.expectObserveFolder(callCount: 1, folderID: sut.testFolderID)

        sut.viewModel.onAppear()
        try? await Task.sleep(nanoseconds: 300_000_000)

        sut.mockVoiceNoteRepo.verify()
        XCTAssertEqual(sut.viewModel.items.count, 2)

        // 정렬 확인 (초기 createdAt 기준 내림차순)
        if case .voiceNote(let note1) = sut.viewModel.items[0],
           case .voiceNote(let note2) = sut.viewModel.items[1]
        {
            XCTAssertGreaterThanOrEqual(note1.createdAt, note2.createdAt)
        } else {
            XCTFail("리스트의 아이템이 VoiceNote 타입이 아닙니다.")
        }
    }

    func test_선택모드_토글_및_아이템선택() {
        let sut = makeSUT()
        let voiceNote = VoiceNote.stub(title: "테스트 노트")

        // 선택 모드 켜기
        sut.viewModel.setSelectionMode(.multiple)
        XCTAssertEqual(sut.viewModel.select, .multiple)

        // 아이템 선택
        sut.viewModel.selectItem(voiceNote)
        XCTAssertEqual(sut.viewModel.selectedItems.count, 1)
        XCTAssertEqual(sut.viewModel.selectedItems.first?.id, voiceNote.id)

        // 아이템 해제
        sut.viewModel.deselectItem(voiceNote)
        XCTAssertTrue(sut.viewModel.selectedItems.isEmpty)

        // 아이템 선택 후 선택 모드 종료 시 초기화 확인
        sut.viewModel.selectItem(voiceNote)
        sut.viewModel.setSelectionMode(.none)
        XCTAssertEqual(sut.viewModel.select, .none)
        XCTAssertTrue(sut.viewModel.selectedItems.isEmpty)
    }

    func test_정렬기준_변경() async {
        let sut = makeSUT()
        let olderNote = VoiceNote.stub(
            id: UUID(),
            createdAt: Date().addingTimeInterval(-1000),
            updatedAt: Date().addingTimeInterval(-100)
        )
        let newerNote = VoiceNote.stub(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date().addingTimeInterval(-1000) // update 기준으로는 더 이전
        )

        sut.mockVoiceNoteRepo.setObserveFolderResult(.success(makeStream([olderNote, newerNote])))
        sut.mockVoiceNoteRepo.expectObserveFolder(callCount: 1, folderID: sut.testFolderID)

        sut.viewModel.onAppear()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // 기본은 생성일 순(createdAt 내림차순)
        if case .voiceNote(let topNote) = sut.viewModel.items[0] {
            XCTAssertEqual(topNote.id, newerNote.id)
        }

        // 수정일 순으로 변경 (updatedAt 내림차순)
        sut.viewModel.setOrder(.updatedAt)
        if case .voiceNote(let topNote) = sut.viewModel.items[0] {
            XCTAssertEqual(topNote.id, olderNote.id) // olderNote의 updatedAt이 최신
        }
    }

    func test_move_호출시_아이템제거및_선택모드해제() async {
        let sut = makeSUT()
        let note = VoiceNote.stub(title: "삭제할 노트")
        let trash = Folder.stub(kind: .trash)

        sut.mockVoiceNoteRepo.setObserveFolderResult(.success(makeStream([note])))
        sut.mockVoiceNoteRepo.expectObserveFolder(callCount: 1, folderID: sut.testFolderID)
        sut.viewModel.onAppear()
        try? await Task.sleep(nanoseconds: 300_000_000)

        sut.viewModel.selectItem(note)

        sut.mockFolderRepo.setFetchByKindResult(.trash, result: .success([trash]))
        sut.mockVoiceNoteRepo.setFetchResult(.success(note))
        sut.mockVoiceNoteRepo.setUpdateResult(.success(note))
        sut.mockVoiceNoteRepo.expectUpdate(callCount: 1)

        sut.viewModel.move()

        sut.mockVoiceNoteRepo.verify()
        XCTAssertTrue(sut.viewModel.items.isEmpty)
        XCTAssertEqual(sut.viewModel.select, .none)
        XCTAssertTrue(sut.viewModel.selectedItems.isEmpty)
    }
}
