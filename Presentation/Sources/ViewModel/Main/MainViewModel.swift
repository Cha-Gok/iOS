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
    @ObservationIgnored
    var didScroll: Bool = false

    var shouldGroupSelectedCategory: Bool {
        selectedCategoryIndex == 1
    }

    var isEmptyList: Bool {
        categoryData[selectedCategoryIndex].items.isEmpty
    }

    var errorMessage: String?

    // MARK: - UseCase

    let voiceNoteUseCase: any VoiceNoteUseCase
    let folderUseCase: any FolderUseCase
    let wasteBasketRepository: any WasteBasketRepository

    // TODO: 화면 전환
    public weak var mainCoordinator: MainCoordinatorDelegate?

    public init(
        voiceNoteUseCase: any VoiceNoteUseCase,
        folderUseCase: any FolderUseCase,
        wasteBasketRepository: any WasteBasketRepository
    ) {
        self.voiceNoteUseCase = voiceNoteUseCase
        self.folderUseCase = folderUseCase
        self.wasteBasketRepository = wasteBasketRepository
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
                let voiceNotes: [VoiceNote] = try await voiceNoteUseCase
                    .fetchRecent(limit: Policy.recentVoiceNoteLimit)
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
                let voiceNotes: [VoiceNote] = try await voiceNoteUseCase.fetchAllFromDefaultFolder()
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
                let folders: [Folder] = try await folderUseCase.fetchDeletableFolders()
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
                let wasteBasket: [WasteBasketItem] = try await wasteBasketRepository.fetchAll()
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
                voiceNoteUseCase: PreviewVoiceNoteUseCase(
                    recentItems: previewData.recentVoiceNotes,
                    defaultItems: previewData.defaultVoiceNotes
                ),
                folderUseCase: PreviewFolderUseCase(items: previewData.folders),
                wasteBasketRepository: PreviewWasteBasketRepository(items: previewData.wasteBasketItems)
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
                    let createdOffset = TimeInterval((index + 1) * 1800) * -1
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
                    -600, -3600, -21600,
                    -86400, -172_800, -259_200, -432_000,
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
                    let createdOffset = TimeInterval((index + 1) * 86400) * -1
                    return Folder(
                        name: "개인 폴더 \(index + 1)",
                        createdAt: now.addingTimeInterval(createdOffset),
                        content: Array(defaultVoiceNotes.prefix((index % 4) + 1)),
                        isDeletable: true
                    )
                }

                let wasteBasketItems: [WasteBasketItem] = (0 ..< 10).map { index in
                    if index.isMultiple(of: 2) {
                        let createdOffset = TimeInterval((index + 2) * 43200) * -1
                        let updatedOffset = TimeInterval((index + 1) * 21600) * -1

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
                        let createdOffset = TimeInterval((index + 1) * 64800) * -1
                        let deletedOffset = TimeInterval((index + 1) * 10800) * -1

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
                    audioFilePath: "VoiceRecords/\(UUID().uuidString).m4a",
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

        struct PreviewVoiceNoteUseCase: VoiceNoteUseCase {
            let recentItems: [VoiceNote]
            let defaultItems: [VoiceNote]

            func create(_ voiceRecord: VoiceRecord) async throws(VoiceNoteUseCaseError) -> VoiceNote {
                defaultItems[0]
            }

            func fetchAllFromDefaultFolder() async throws(VoiceNoteUseCaseError) -> [VoiceNote] {
                defaultItems
            }

            func fetchRecent(limit: Int) async throws(VoiceNoteUseCaseError) -> [VoiceNote] {
                Array(recentItems.prefix(limit))
            }

            func fetchAll(folderID: UUID) async throws(VoiceNoteUseCaseError) -> [VoiceNote] {
                defaultItems.filter { $0.folderID == folderID }
            }

            func fetch(byId id: UUID) async throws(VoiceNoteUseCaseError) -> VoiceNote {
                guard let item = defaultItems.first(where: { $0.id == id }) else {
                    throw .recordNotFound(id)
                }
                return item
            }

            func update(_ voiceNote: VoiceNote) async throws(VoiceNoteUseCaseError) -> VoiceNote {
                voiceNote
            }

            func summarize(
                audioFilePath: String,
                language: Language
            ) async throws(VoiceNoteUseCaseError) -> AudioToSummaryResult {
                AudioToSummaryResult(transcript: Transcript(text: ""), keywords: [], summary: Summary(text: ""))
            }
        }

        struct PreviewFolderUseCase: FolderUseCase {
            let items: [Folder]

            func create(name: String) async throws(FolderUseCaseError) -> Folder {
                items[0]
            }

            func createDefault() async throws(FolderUseCaseError) -> Folder {
                items[0]
            }

            func fetchAll() async throws(FolderUseCaseError) -> [Folder] {
                items
            }

            func fetchDeletableFolders() async throws(FolderUseCaseError) -> [Folder] {
                items.filter(\.isDeletable)
            }

            func fetch(by id: UUID) async throws(FolderUseCaseError) -> Folder {
                guard let item = items.first(where: { $0.id == id }) else { throw .notFound }
                return item
            }

            func update(_ folder: Folder) async throws(FolderUseCaseError) -> Folder {
                folder
            }
        }

        struct PreviewWasteBasketRepository: WasteBasketRepository {
            let items: [WasteBasketItem]

            func fetchAll() async throws(FetchWasteBasketRepositoryError) -> [WasteBasketItem] {
                items
            }

            func allClear() async throws(DeleteWasteBasketRepositoryError) {}
            func delete(item: WasteBasketItem) async throws(DeleteWasteBasketRepositoryError) {}
            func deleteAll(items: [WasteBasketItem]) async throws(DeleteWasteBasketRepositoryError) {}
            func moveToWasteBasket(item: WasteBasketItem) async throws(MoveWasteBasketRepositoryError) {}
            func moveAllToWasteBasket(items: [WasteBasketItem]) async throws(MoveWasteBasketRepositoryError) {}
            func restore(item: WasteBasketItem) async throws(RestoreWasteBasketRepositoryError) {}
            func restoreAll(items: [WasteBasketItem]) async throws(RestoreWasteBasketRepositoryError) {}
        }
    }
#endif
