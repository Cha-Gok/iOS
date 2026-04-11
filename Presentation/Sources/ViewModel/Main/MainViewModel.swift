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

    @ObservationIgnored
    private(set) var selectedCategoryIndex: Int = 0

    var isEmptyList: Bool {
        categoryData[selectedCategoryIndex].items.isEmpty
    }

    var errorMessage: String?

    // MARK: - UseCase

    let fetchRecentVoiceNoteUseCase: FetchRecentVoiceNoteUseCase
    let fetchVoiceNoteUseCase: FetchVoiceNoteUseCase
    let fetchFolderUseCase: FetchFolderUseCase
    let fetchTrashUseCase: FetchWasteBasketFolderUseCase

    // TODO: 화면 전환
    public weak var mainCoordinator: MainCoordinatorDelegate?

    public init(
        fetchRecentVoiceNoteUseCase: FetchRecentVoiceNoteUseCase,
        fetchVoiceNoteUseCase: FetchVoiceNoteUseCase,
        fetchFolderUseCase: FetchFolderUseCase,
        fetchTrashUseCase: FetchWasteBasketFolderUseCase
    ) {
        self.fetchRecentVoiceNoteUseCase = fetchRecentVoiceNoteUseCase
        self.fetchVoiceNoteUseCase = fetchVoiceNoteUseCase
        self.fetchFolderUseCase = fetchFolderUseCase
        self.fetchTrashUseCase = fetchTrashUseCase
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

// MARK: - Update CategoryData

extension MainViewModel {
    /// 최근 기록(전체 폴더 최신 5개) 업데이트 함수
    func updateRecentCategory() {
        Task {
            do {
                let voiceNotes: [VoiceNote] = try await fetchRecentVoiceNoteUseCase.execute()
                let items: [LibraryItem] = voiceNotes.map { .voiceNote($0) }
                categoryData[0].items = items
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }

    /// 기본 폴더(음성 노트) 업데이트 함수
    func updateVoiceNoteCategory() {
        Task {
            do {
                let voiceNotes: [VoiceNote] = try await fetchVoiceNoteUseCase.execute()
                let items: [LibraryItem] = voiceNotes.map { .voiceNote($0) }
                categoryData[1].items = items
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }

    /// 폴더 영속성 업데이트 함수
    func updateMyFolderCategory() {
        Task {
            do {
                let folders: [Folder] = try await fetchFolderUseCase.fetchDeletableFolders()
                let items: [LibraryItem] = folders.map { folder in
                    LibraryItem.folder(folder)
                }
                categoryData[2].items = items
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }

    /// 휴지통 영속성 업데이트 함수
    func updateTrashCategory() {
        Task {
            do {
                let wasteBasket: [WasteBasketItem] = try await fetchTrashUseCase.execute()
                let items: [LibraryItem] = wasteBasket.map(\.toLibraryItem)
                categoryData[3].items = items
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }
}
