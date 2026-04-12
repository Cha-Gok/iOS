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

    var shouldGroupSelectedCategory: Bool {
        selectedCategoryIndex == 1
    }
    
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

    func pushVoiceNoteView(voiceNote: VoiceNote) {
        mainCoordinator?.pushVoiceNoteView(voiceNote: voiceNote)
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

#if DEBUG
extension MainViewModel {
    static func preview(selectedCategoryIndex: Int = 0) -> MainViewModel {
        let previewData = PreviewData.make()
        let viewModel = MainViewModel(
            fetchRecentVoiceNoteUseCase: PreviewFetchRecentVoiceNoteUseCase(items: previewData.recentVoiceNotes),
            fetchVoiceNoteUseCase: PreviewFetchVoiceNoteUseCase(items: previewData.defaultVoiceNotes),
            fetchFolderUseCase: PreviewFetchFolderUseCase(items: previewData.folders),
            fetchTrashUseCase: PreviewFetchWasteBasketFolderUseCase(items: previewData.wasteBasketItems)
        )

        viewModel.categoryData[0].items = previewData.recentVoiceNotes.map(LibraryItem.voiceNote)
        viewModel.categoryData[1].items = previewData.defaultVoiceNotes.map(LibraryItem.voiceNote)
        viewModel.categoryData[2].items = previewData.folders.map(LibraryItem.folder)
        viewModel.categoryData[3].items = previewData.wasteBasketItems.map(\.toLibraryItem)
        viewModel.selectedCategoryIndex = max(0, min(selectedCategoryIndex, viewModel.categoryData.count - 1))

        return viewModel
    }
}

private extension MainViewModel {
    struct PreviewData {
        let recentVoiceNotes: [VoiceNote]
        let defaultVoiceNotes: [VoiceNote]
        let folders: [Folder]
        let wasteBasketItems: [WasteBasketItem]

        static func make(now: Date = .now) -> Self {
            let defaultFolderID = UUID()
            let personalFolderID = UUID()

            let recentVoiceNotes: [VoiceNote] = (0 ..< 10).map { index in
                let createdOffset = TimeInterval((index + 1) * 1_800) * -1
                let updatedOffset = TimeInterval((index + 1) * 900) * -1
                let duration = Double(180 + index * 35)

                return Self.makeVoiceNote(
                    title: "최근 기록 \(index + 1)",
                    createdAt: now.addingTimeInterval(createdOffset),
                    updatedAt: now.addingTimeInterval(updatedOffset),
                    folderID: defaultFolderID,
                    duration: duration,
                    summarized: index.isMultiple(of: 2)
                )
            }

            let defaultOffsets: [TimeInterval] = [
                -600, -3_600, -21_600,
                -86_400, -172_800, -259_200, -432_000,
                -864_000, -1_209_600, -2_592_000
            ]
            let defaultVoiceNotes: [VoiceNote] = defaultOffsets.enumerated().map { index, offset in
                Self.makeVoiceNote(
                    title: "기본 폴더 메모 \(index + 1)",
                    createdAt: now.addingTimeInterval(offset),
                    updatedAt: now.addingTimeInterval(offset / 2),
                    folderID: defaultFolderID,
                    duration: Double(240 + index * 20),
                    summarized: index.isMultiple(of: 3)
                )
            }

            let folders: [Folder] = (0 ..< 10).map { index in
                let createdOffset = TimeInterval((index + 1) * 86_400) * -1
                return Folder(
                    name: "개인 폴더 \(index + 1)",
                    createdAt: now.addingTimeInterval(createdOffset),
                    content: Array(defaultVoiceNotes.prefix((index % 4) + 1)),
                    isDeletable: true
                )
            }

            let wasteBasketItems: [WasteBasketItem] = (0 ..< 10).map { index in
                if index.isMultiple(of: 2) {
                    let createdOffset = TimeInterval((index + 2) * 43_200) * -1
                    let updatedOffset = TimeInterval((index + 1) * 21_600) * -1

                    return .voiceNote(
                        obj: Self.makeVoiceNote(
                            title: "휴지통 메모 \(index + 1)",
                            createdAt: now.addingTimeInterval(createdOffset),
                            updatedAt: now.addingTimeInterval(updatedOffset),
                            folderID: personalFolderID,
                            duration: Double(120 + index * 15),
                            summarized: false
                        )
                    )
                } else {
                    let createdOffset = TimeInterval((index + 1) * 64_800) * -1
                    let deletedOffset = TimeInterval((index + 1) * 10_800) * -1

                    return .folder(
                        obj: Folder(
                            name: "휴지통 폴더 \(index + 1)",
                            createdAt: now.addingTimeInterval(createdOffset),
                            content: [],
                            isDeletable: true,
                            deletedAt: now.addingTimeInterval(deletedOffset)
                        )
                    )
                }
            }

            return PreviewData(
                recentVoiceNotes: recentVoiceNotes,
                defaultVoiceNotes: defaultVoiceNotes,
                folders: folders,
                wasteBasketItems: wasteBasketItems
            )
        }

        static func makeVoiceNote(
            title: String,
            createdAt: Date,
            updatedAt: Date,
            folderID: UUID,
            duration: Double,
            summarized: Bool
        ) -> VoiceNote {
            let record = VoiceRecord(
                createdAt: createdAt,
                audioFilePath: URL(fileURLWithPath: "/tmp/\(UUID().uuidString).m4a"),
                duration: duration
            )

            return VoiceNote(
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
                folderID: folderID,
                voiceRecord: record,
                transcript: summarized ? Transcript(text: "\(title) 전사본") : nil,
                summary: summarized ? Summary(text: "\(title) 요약") : nil
            )
        }
    }

    struct PreviewFetchRecentVoiceNoteUseCase: FetchRecentVoiceNoteUseCase {
        let items: [VoiceNote]

        func execute() async throws(FetchRecentVoiceNoteUseCaseError) -> [VoiceNote] {
            items
        }
    }

    struct PreviewFetchVoiceNoteUseCase: FetchVoiceNoteUseCase {
        let items: [VoiceNote]

        func execute() async throws(FetchVoiceNoteUseCaseError) -> [VoiceNote] {
            items
        }

        func execute(folderID: UUID) async throws(FetchVoiceNoteUseCaseError) -> [VoiceNote] {
            items.filter { $0.folderID == folderID }
        }

        func execute(byId id: UUID) async throws(FetchVoiceNoteUseCaseError) -> VoiceNote {
            guard let item = items.first(where: { $0.id == id }) else {
                throw .recordNotFound(id: id)
            }
            return item
        }
    }

    struct PreviewFetchFolderUseCase: FetchFolderUseCase {
        let items: [Folder]

        func fetchAll() async throws(FetchFolderUseCaseError) -> [Folder] {
            items
        }

        func fetchDeletableFolders() async throws(FetchFolderUseCaseError) -> [Folder] {
            items.filter(\.isDeletable)
        }

        func fetch(by id: UUID) async throws(FetchFolderUseCaseError) -> Folder {
            guard let item = items.first(where: { $0.id == id }) else {
                throw .notFound
            }
            return item
        }
    }

    struct PreviewFetchWasteBasketFolderUseCase: FetchWasteBasketFolderUseCase {
        let items: [WasteBasketItem]

        func execute() async throws(FetchWasteBasketFolderUseCaseError) -> [WasteBasketItem] {
            items
        }
    }
}
#endif
