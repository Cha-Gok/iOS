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

    private(set) var showPermissionAlert: Bool = false
    private(set) var showLanguageAlert: Bool = false

    private(set) var errorMessage: String?

    // MARK: - UseCase

    let microphoneRepository: VoiceRecordRepository
    let voiceNoteUseCase: any VoiceNoteUseCase
    let folderUseCase: any FolderUseCase
    let trashUseCase: any TrashUseCase
    let languageRepository: any LanguageRepository

    @ObservationIgnored
    private var recentTask: Task<Void, Never>?
    @ObservationIgnored
    private var voiceNoteTask: Task<Void, Never>?
    @ObservationIgnored
    private var myFolderTask: Task<Void, Never>?
    @ObservationIgnored
    private var trashTask: Task<Void, Never>?

    // TODO: 화면 전환
    public weak var mainCoordinator: MainCoordinatorDelegate?

    public init(
        microphoneRepository: any VoiceRecordRepository,
        voiceNoteUseCase: any VoiceNoteUseCase,
        folderUseCase: any FolderUseCase,
        trashUseCase: any TrashUseCase,
        languageRepository: any LanguageRepository
    ) {
        self.microphoneRepository = microphoneRepository
        self.voiceNoteUseCase = voiceNoteUseCase
        self.folderUseCase = folderUseCase
        self.trashUseCase = trashUseCase
        self.languageRepository = languageRepository
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

    func closePermissionAlert() {
        showPermissionAlert = false
    }

    func openPermissionAlert() {
        showPermissionAlert = true
    }

    func closeLanguageAlert() {
        showLanguageAlert = false
    }

    func openLanguageAlert() {
        showLanguageAlert = true
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
    /// 최근 기록(전체 폴더 최신 5개) 관찰 시작
    func updateRecentCategory() {
        guard recentTask == nil else { return }
        recentTask = Task { [weak self] in
            guard let self else { return }
            do {
                let stream = try voiceNoteUseCase.observeRecent(limit: Policy.recentVoiceNoteLimit)
                for await voiceNotes in stream {
                    categoryData[0].items = voiceNotes.map { .voiceNote($0) }
                }
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }

    /// 기본 폴더(음성 노트) 관찰 시작
    func updateVoiceNoteCategory() {
        guard voiceNoteTask == nil else { return }
        voiceNoteTask = Task { [weak self] in
            guard let self else { return }
            do {
                let defaultFolder = try folderUseCase.fetchDefault()
                let stream = try voiceNoteUseCase.observe(folderID: defaultFolder.id)
                for await voiceNotes in stream {
                    categoryData[1].items = voiceNotes.map { .voiceNote($0) }
                }
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }

    /// 개인 폴더 관찰 시작
    func updateMyFolderCategory() {
        guard myFolderTask == nil else { return }
        myFolderTask = Task { [weak self] in
            guard let self else { return }
            do {
                let stream = try folderUseCase.observeDeletableFolders()
                for await folders in stream {
                    categoryData[2].items = folders.map { LibraryItem.folder($0) }
                }
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }

    /// 휴지통 관찰 시작
    func updateTrashCategory() {
        guard trashTask == nil else { return }
        trashTask = Task { [weak self] in
            guard let self else { return }
            do {
                let stream = try trashUseCase.observe()
                for await wasteBasket in stream {
                    categoryData[3].items = wasteBasket.map(\.toLibraryItem)
                }
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }

    /// 관찰 중인 모든 카테고리 stream을 취소합니다.
    func cancelObservations() {
        recentTask?.cancel()
        recentTask = nil
        voiceNoteTask?.cancel()
        voiceNoteTask = nil
        myFolderTask?.cancel()
        myFolderTask = nil
        trashTask?.cancel()
        trashTask = nil
    }
}

// MARK: - Mic Permission

extension MainViewModel {
    func handleRecordButtonTap() {
        let status = microphoneRepository.checkMicrophonePermission()
        if status != .authorized {
            openPermissionAlert()
        } else {
            presentRecodingView()
        }
    }
}

// MARK: - Language Method

extension MainViewModel {
    func checkLanguage() -> Language {
        languageRepository.fetchLanguage()
    }

    func saveLanguage(_ lang: Language) {
        languageRepository.saveLanguage(lang)
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
                trashUseCase: PreviewTrashUseCase(items: previewData.wasteBasketItems),
                languageRepository: PreviewLanguageRepository()
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
                    let prefixCount = (index % 4) + 1
                    let noteIDs = Array(defaultVoiceNotes.prefix(prefixCount).map(\.id))
                    return Folder(
                        name: "개인 폴더 \(index + 1)",
                        createdAt: now.addingTimeInterval(createdOffset),
                        voiceNoteIDs: noteIDs,
                        kind: .custom
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
                                kind: .custom,
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
                    transcript: summarized
                        ? Transcript(sections: [TranscriptSection(timestamp: 0, text: "\(title) 전사본")])
                        : nil,
                    summary: summarized ? Summary(text: "\(title) 요약") : nil,
                    analysisState: summarized ? .completed : .pending
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

            func fetch(byId id: UUID) throws(VoiceNoteUseCaseError) -> VoiceNote {
                guard let item = defaultItems.first(where: { $0.id == id }) else {
                    throw .recordNotFound(id)
                }
                return item
            }

            func update(_ voiceNote: VoiceNote) throws(VoiceNoteUseCaseError) -> VoiceNote {
                voiceNote
            }

            func observe(id: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<VoiceNote> {
                guard let item = defaultItems.first(where: { $0.id == id }) else {
                    throw .recordNotFound(id)
                }
                return AsyncStream { $0.yield(item) }
            }

            func observe(folderID: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]> {
                let filtered = defaultItems.filter { $0.folderID == folderID }
                return AsyncStream { continuation in
                    continuation.yield(filtered)
                    continuation.finish()
                }
            }

            func observeRecent(limit: Int) throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]> {
                let recent = Array(recentItems.prefix(limit))
                return AsyncStream { continuation in
                    continuation.yield(recent)
                    continuation.finish()
                }
            }

            func regenerateSummary(id _: UUID) {}

            func moveToTrash(noteID _: UUID) throws(VoiceNoteUseCaseError) {}
            func restore(noteID _: UUID) throws(VoiceNoteUseCaseError) {}
            func delete(noteID _: UUID) throws(VoiceNoteUseCaseError) {}
        }

        struct PreviewFolderUseCase: FolderUseCase {
            let items: [Folder]

            func create(name: String) throws(FolderUseCaseError) -> Folder {
                items[0]
            }

            func createDefault() throws(FolderUseCaseError) -> Folder {
                items[0]
            }

            func createTrash() throws(FolderUseCaseError) -> Folder {
                items[0]
            }

            func fetchAll() throws(FolderUseCaseError) -> [Folder] {
                items
            }

            func fetchDefault() throws(FolderUseCaseError) -> Folder {
                guard let folder = items.first(where: { $0.kind == .default }) else { throw .notFound }
                return folder
            }

            func fetchTrash() throws(FolderUseCaseError) -> Folder {
                guard let folder = items.first(where: { $0.kind == .trash }) else { throw .notFound }
                return folder
            }

            func fetchDeletableFolders() throws(FolderUseCaseError) -> [Folder] {
                items.filter { $0.kind == .custom }
            }

            func fetch(by id: UUID) throws(FolderUseCaseError) -> Folder {
                guard let item = items.first(where: { $0.id == id }) else { throw .notFound }
                return item
            }

            func update(_ folder: Folder) throws(FolderUseCaseError) -> Folder {
                folder
            }

            func observeDeletableFolders() throws(FolderUseCaseError) -> AsyncStream<[Folder]> {
                let snapshot = items.filter { $0.kind == .custom }
                return AsyncStream { continuation in
                    continuation.yield(snapshot)
                    continuation.finish()
                }
            }

            func moveToTrash(folderID _: UUID) throws(FolderUseCaseError) {}
            func restore(folderID _: UUID) throws(FolderUseCaseError) {}
            func delete(folderID _: UUID) throws(FolderUseCaseError) {}
        }

        struct PreviewTrashUseCase: TrashUseCase {
            let items: [WasteBasketItem]

            func observe() throws(TrashUseCaseError) -> AsyncStream<[WasteBasketItem]> {
                let snapshot = items
                return AsyncStream { continuation in
                    continuation.yield(snapshot)
                    continuation.finish()
                }
            }

            func moveToTrash(noteID _: UUID) throws(TrashUseCaseError) {}
            func moveToTrash(folderID _: UUID) throws(TrashUseCaseError) {}
            func restoreNote(id _: UUID) throws(TrashUseCaseError) {}
            func restoreFolder(id _: UUID) throws(TrashUseCaseError) {}
            func restore(item _: WasteBasketItem) throws(TrashUseCaseError) {}
            func restoreAll(items _: [WasteBasketItem]) throws(TrashUseCaseError) {}
            func hardDeleteNote(id _: UUID) throws(TrashUseCaseError) {}
            func hardDeleteFolder(id _: UUID) throws(TrashUseCaseError) {}
            func delete(item _: WasteBasketItem) throws(TrashUseCaseError) {}
            func deleteAll(items _: [WasteBasketItem]) throws(TrashUseCaseError) {}
            func allClear() throws(TrashUseCaseError) {}
        }

        struct PreviewLanguageRepository: LanguageRepository {
            func fetchLanguage() -> Language {
                .ko
            }

            func saveLanguage(_ language: Language) {
                AppLogger.info("Language State : \(language)")
            }
        }
    }
#endif
