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
    private(set) var didScroll: Bool = false

    var shouldGroupSelectedCategory: Bool {
        selectedCategoryIndex == 1
    }

    var isEmptyList: Bool {
        categoryData[selectedCategoryIndex].items.isEmpty
    }

    private(set) var showAlert: Bool = false

    private(set) var errorMessage: String?

    // MARK: - UseCase

    let microphoneRepository: VoiceRecordRepository
    let voiceNoteUseCase: any VoiceNoteUseCase
    let folderUseCase: any FolderUseCase
    let wasteBasketRepository: any WasteBasketRepository

    // TODO: 화면 전환
    public weak var mainCoordinator: MainCoordinatorDelegate?

    public init(
        microphoneRepository: any VoiceRecordRepository,
        voiceNoteUseCase: any VoiceNoteUseCase,
        folderUseCase: any FolderUseCase,
        wasteBasketRepository: any WasteBasketRepository
    ) {
        self.microphoneRepository = microphoneRepository
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

    func setDidScroll(_ didScroll: Bool) {
        self.didScroll = didScroll
    }

    func closeAlertView() {
        showAlert = false
    }

    func openAlertView() {
        showAlert = true
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
        do {
            let voiceNotes: [VoiceNote] = try voiceNoteUseCase
                .fetchRecent(limit: Policy.recentVoiceNoteLimit)
            let items: [LibraryItem] = voiceNotes.map { .voiceNote($0) }
            categoryData[0].items = items
        } catch {
            AppLogger.error(error)
            errorMessage = error.localizedDescription
        }
    }

    /// 기본 폴더(음성 노트) 업데이트 함수
    func updateVoiceNoteCategory() {
        do {
            let voiceNotes: [VoiceNote] = try voiceNoteUseCase.fetchAllFromDefaultFolder()
            let items: [LibraryItem] = voiceNotes.map { .voiceNote($0) }
            categoryData[1].items = items
        } catch {
            AppLogger.error(error)
            errorMessage = error.localizedDescription
        }
    }

    /// 폴더 영속성 업데이트 함수
    func updateMyFolderCategory() {
        do {
            let folders: [Folder] = try folderUseCase.fetchDeletableFolders()
            let items: [LibraryItem] = folders.map { folder in
                LibraryItem.folder(folder)
            }
            categoryData[2].items = items
        } catch {
            AppLogger.error(error)
            errorMessage = error.localizedDescription
        }
    }

    /// 휴지통 영속성 업데이트 함수
    func updateTrashCategory() {
        do {
            let wasteBasket: [WasteBasketItem] = try wasteBasketRepository.fetchAll()
            let items: [LibraryItem] = wasteBasket.map(\.toLibraryItem)
            categoryData[3].items = items
        } catch {
            AppLogger.error(error)
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Mic Permission

extension MainViewModel {
    func handleRecordButtonTap() {
        let status = microphoneRepository.checkMicrophonePermission()
        if status != .authorized {
            openAlertView()
        } else {
            presentRecodingView()
        }
    }
}

#if DEBUG
    extension MainViewModel {
        static func preview(selectedCategoryIndex: Int = 0) -> MainViewModel {
            let previewData = PreviewData.make()
            let viewModel = MainViewModel(
                microphoneRepository: PreviewMicrophoneRepository(),
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

        struct PreviewMicrophoneRepository: VoiceRecordRepository {
            func checkMicrophonePermission() -> PermissionStatus {
                .denied
            }

            func requestMicrophonePermission() async throws(Domain.VoiceRecordRepositoryError) -> Domain
                .PermissionStatus
            {
                .authorized
            }

            func startRecording() async throws(Domain.VoiceRecordRepositoryError) -> AsyncStream<Domain.Waveform> {
                AsyncStream { continuation in
                    continuation.yield(Domain.Waveform(amplitudes: [0.12, 0.31, 0.45, 0.22, 0.38]))
                    continuation.yield(Domain.Waveform(amplitudes: [0.27, 0.51, 0.18, 0.34, 0.42]))
                    continuation.finish()
                }
            }

            func pauseRecording() async throws(Domain.VoiceRecordRepositoryError) {
                // Preview mock: no-op
            }

            func resumeRecording() async throws(Domain.VoiceRecordRepositoryError) {
                // Preview mock: no-op
            }

            func finishRecording() async throws(Domain.VoiceRecordRepositoryError) -> Domain.VoiceRecord {
                Domain.VoiceRecord(
                    createdAt: .now,
                    audioFilePath: "VoiceRecords/preview.m4a",
                    duration: 95
                )
            }

            func cancelRecording() async throws(Domain.VoiceRecordRepositoryError) {
                // Preview mock: no-op
            }
        }

        struct PreviewVoiceNoteUseCase: VoiceNoteUseCase {
            let recentItems: [VoiceNote]
            let defaultItems: [VoiceNote]

            func create(_ voiceRecord: VoiceRecord) throws(VoiceNoteUseCaseError) -> VoiceNote {
                defaultItems[0]
            }

            func fetchAllFromDefaultFolder() throws(VoiceNoteUseCaseError) -> [VoiceNote] {
                defaultItems
            }

            func fetchRecent(limit: Int) throws(VoiceNoteUseCaseError) -> [VoiceNote] {
                Array(recentItems.prefix(limit))
            }

            func fetchAll(folderID: UUID) throws(VoiceNoteUseCaseError) -> [VoiceNote] {
                defaultItems.filter { $0.folderID == folderID }
            }

            func fetch(byId id: UUID) throws(VoiceNoteUseCaseError) -> VoiceNote {
                guard let item = defaultItems.first(where: { $0.id == id }) else {
                    throw .recordNotFound(id)
                }
                return item
            }

            func update(_ voiceNote: VoiceNote) throws(VoiceNoteUseCaseError) -> VoiceNote {
                voiceNote
            }

            func transcribe(audioFilePath: String) async throws(VoiceNoteUseCaseError) -> Transcript {
                Transcript(text: "")
            }

            func summarize(
                transcript: Transcript,
                language: Language
            ) async throws(VoiceNoteUseCaseError) -> (keywords: [Keyword], summary: Summary) {
                (keywords: [], summary: Summary(text: ""))
            }

            func observe(id: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<VoiceNote> {
                guard let item = defaultItems.first(where: { $0.id == id }) else {
                    throw .recordNotFound(id)
                }
                return AsyncStream { $0.yield(item) }
            }
        }

        struct PreviewFolderUseCase: FolderUseCase {
            let items: [Folder]

            func create(name: String) throws(FolderUseCaseError) -> Folder {
                items[0]
            }

            func createDefault() throws(FolderUseCaseError) -> Folder {
                items[0]
            }

            func fetchAll() throws(FolderUseCaseError) -> [Folder] {
                items
            }

            func fetchDeletableFolders() throws(FolderUseCaseError) -> [Folder] {
                items.filter(\.isDeletable)
            }

            func fetch(by id: UUID) throws(FolderUseCaseError) -> Folder {
                guard let item = items.first(where: { $0.id == id }) else { throw .notFound }
                return item
            }

            func update(_ folder: Folder) throws(FolderUseCaseError) -> Folder {
                folder
            }
        }

        struct PreviewWasteBasketRepository: WasteBasketRepository {
            let items: [WasteBasketItem]

            func fetchAll() throws(FetchWasteBasketRepositoryError) -> [WasteBasketItem] {
                items
            }

            func allClear() throws(DeleteWasteBasketRepositoryError) {}
            func delete(item: WasteBasketItem) throws(DeleteWasteBasketRepositoryError) {}
            func deleteAll(items: [WasteBasketItem]) throws(DeleteWasteBasketRepositoryError) {}
            func moveToWasteBasket(item: WasteBasketItem) throws(MoveWasteBasketRepositoryError) {}
            func moveAllToWasteBasket(items: [WasteBasketItem]) throws(MoveWasteBasketRepositoryError) {}
            func restore(item: WasteBasketItem) throws(RestoreWasteBasketRepositoryError) {}
            func restoreAll(items: [WasteBasketItem]) throws(RestoreWasteBasketRepositoryError) {}
        }
    }
#endif
