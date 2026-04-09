import Core
import Domain
import Foundation

@MainActor
@Observable
public final class MainViewModel {
    // MARK: - State

    /// 통합된 카테고리 데이터
    private(set) var categoryData: [CategoryToggle] = [
        CategoryToggle(
            imageName: "clock",
            title: "최근 기록",
            items: []
        ),
        CategoryToggle(
            imageName: "folder",
            title: "기본 폴더",
            items: []
        ),
        CategoryToggle(
            imageName: "folder",
            title: "개인 폴더",
            items: []
        ),
        CategoryToggle(
            imageName: "trash",
            title: "휴지통",
            items: []
        )
    ]

    private(set) var selectedCategoryIndex: Int = 0

    var isEmptyList: Bool {
        categoryData[selectedCategoryIndex].items.isEmpty
    }

    // MARK: - UseCase

    let fetchFolderUseCase: FetchFolderUseCase
    let fetchVoiceNoteUseCase: FetchVoiceNoteUseCase
    let fetchRecentVoiceNoteUseCase: FetchRecentVoiceNoteUseCase

    // TODO: 화면 전환
    public weak var mainCoordinator: MainViewCoordinatorDelegate?

    public init(
        fetchFolderUseCase: FetchFolderUseCase,
        fetchVoiceNoteUseCase: FetchVoiceNoteUseCase,
        fetchRecentVoiceNoteUseCase: FetchRecentVoiceNoteUseCase
    ) {
        self.fetchFolderUseCase = fetchFolderUseCase
        self.fetchVoiceNoteUseCase = fetchVoiceNoteUseCase
        self.fetchRecentVoiceNoteUseCase = fetchRecentVoiceNoteUseCase
    }
}

// MARK: - Getter / Setter

extension MainViewModel {
    func setSelectedCategoryIndex(indexPath: IndexPath) {
        selectedCategoryIndex = indexPath.item

        // 휴지통 (index 3) 선택 시 화면 전환 트리거
        if selectedCategoryIndex == categoryData.count - 1 {
            pushTrashView()
            // 화면 이동 후 index를 되돌린다.
            selectedCategoryIndex = 0
        }

        if selectedCategoryIndex == categoryData.count - 2 {
            pushMyFolderView()
            // 화면 이동 후 index를 되돌린다.
            selectedCategoryIndex = 0
        }
    }
}

// MARK: - Helper Function

extension MainViewModel {
    func pushTrashView() {
        mainCoordinator?.pushTrashView()
    }

    func pushMyFolderView() {
        mainCoordinator?.pushMyFolderView(category: categoryData[2])
    }

    func presentRecodingView() {
        mainCoordinator?.presentRecodingView()
    }
}

// MARK: - Coordinator Delegate 패턴

@MainActor
public protocol MainViewCoordinatorDelegate: AnyObject {
    /// 휴지통으로 push하는 함수
    func pushTrashView()
    /// 개인 폴더로 push 하는 함수
    func pushMyFolderView(category: CategoryToggle)
    /// 녹음 시작 present 함수
    func presentRecodingView()
    /// 공용 Pop함수
    func pop()
}

// MARK: - Update CategoryData

extension MainViewModel {
    /// 폴더 영속성 업데이트 함수
    func updateMyFolderCategory() {
        Task {
            let folders: [Folder] = try await fetchFolderUseCase.fetchAll()
            categoryData[2].items = folders.map { folder in
                LibraryItem.folder(folder)
            }
        }
    }

    /// 기본 폴더(음성 노트) 업데이트 함수
    func updateVoiceNoteCategory() {
        Task {
            let voiceNotes: [VoiceNote] = await (try? fetchVoiceNoteUseCase.execute()) ?? []
            categoryData[1].items = voiceNotes.map { .voiceNote($0) }
        }
    }

    /// 최근 기록(전체 폴더 최신 5개) 업데이트 함수
    func updateRecentCategory() {
        Task {
            let voiceNotes: [VoiceNote] = await (try? fetchRecentVoiceNoteUseCase.execute()) ?? []
            categoryData[0].items = voiceNotes.map { .voiceNote($0) }
        }
    }
}
