@testable import Presentation
import Domain
import DomainTesting
import XCTest

@MainActor
final class FolderDetailViewModelTests: XCTestCase {
    // MARK: - SUT

    private struct SUT {
        let viewModel: FolderDetailViewModel
        let mockVoiceNoteRepo: MockVoiceNoteRepository
        let mockCoordinator: MockBaseCoordinatorDelegate
        let testFolderID: UUID
    }

    private func makeSUT(title: String = "상세 폴더", folderID: UUID = UUID()) -> SUT {
        let mockVoiceNoteRepo = MockVoiceNoteRepository()
        let mockCoordinator = MockBaseCoordinatorDelegate()

        let viewModel = FolderDetailViewModel(
            title: title,
            folderID: folderID,
            voiceNoteUseCase: DefaultVoiceNoteUseCase(
                repository: mockVoiceNoteRepo,
                sttRepository: MockSTTRepository(),
                summaryRepository: MockSummaryRepository()
            )
        )
        viewModel.coordinator = mockCoordinator

        return SUT(
            viewModel: viewModel,
            mockVoiceNoteRepo: mockVoiceNoteRepo,
            mockCoordinator: mockCoordinator,
            testFolderID: folderID
        )
    }

    // MARK: - Initial State Tests

    func test_초기상태_확인() {
        let folderID = UUID()
        let sut = makeSUT(title: "테스트 폴더", folderID: folderID)

        XCTAssertEqual(sut.viewModel.title, "테스트 폴더")
        XCTAssertEqual(sut.viewModel.folderID, folderID)
        XCTAssertTrue(sut.viewModel.items.isEmpty)
        XCTAssertTrue(sut.viewModel.isEmpty)
        XCTAssertFalse(sut.viewModel.isSelectionMode)
    }

    // MARK: - UI Action Tests

    func test_didTapBack_호출시_Pop() {
        let sut = makeSUT()

        sut.viewModel.didTapBack()

        XCTAssertTrue(sut.mockCoordinator.popCalled)
    }

    func test_fetchItems_호출시_보이스노트로드확인() async {
        let sut = makeSUT()
        let expectedNotes = [
            VoiceNote.stub(title: "노트1"),
            VoiceNote.stub(title: "노트2")
        ]

        await sut.mockVoiceNoteRepo.setFetchAllResult(.success(expectedNotes))
        await sut.mockVoiceNoteRepo.expectFetchAll(callCount: 1, folderID: sut.testFolderID)

        sut.viewModel.fetchItems()
        try? await Task.sleep(nanoseconds: 300_000_000)

        await sut.mockVoiceNoteRepo.verify()
        XCTAssertEqual(sut.viewModel.items.count, 2)
        XCTAssertFalse(sut.viewModel.isEmpty)

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
        sut.viewModel.toggleSelectionMode()
        XCTAssertTrue(sut.viewModel.isSelectionMode)

        // 아이템 선택
        sut.viewModel.selectItem(voiceNote)
        XCTAssertEqual(sut.viewModel.selectedItems.count, 1)
        XCTAssertEqual(sut.viewModel.selectedItems.first?.id, voiceNote.id)

        // 아이템 해제
        sut.viewModel.deselectItem(voiceNote)
        XCTAssertTrue(sut.viewModel.selectedItems.isEmpty)

        // 아이템 선택 후 선택 모드 종료 시 초기화 확인
        sut.viewModel.selectItem(voiceNote)
        sut.viewModel.toggleSelectionMode()
        XCTAssertFalse(sut.viewModel.isSelectionMode)
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

        await sut.mockVoiceNoteRepo.setFetchAllResult(.success([olderNote, newerNote]))
        await sut.mockVoiceNoteRepo.expectFetchAll(callCount: 1, folderID: sut.testFolderID)

        sut.viewModel.fetchItems()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // 기본은 생성일 순(createdAt 내림차순)
        if case .voiceNote(let topNote) = sut.viewModel.items[0] {
            XCTAssertEqual(topNote.id, newerNote.id)
        }

        // 수정일 순으로 변경 (updatedAt 내림차순)
        sut.viewModel.touchUpdatedAction()
        if case .voiceNote(let topNote) = sut.viewModel.items[0] {
            XCTAssertEqual(topNote.id, olderNote.id) // olderNote의 updatedAt이 최신
        }
    }
}
