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
            imageName: "microphone",
            title: "모든 기록",
            items: []
        ),
        CategoryToggle(
            imageName: "folder",
            title: "폴더 목록",
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

    private(set) var errorMessage: String?

    // MARK: - UseCase

    let microphoneRepository: VoiceRecordRepository
    let voiceNoteUseCase: any VoiceNoteUseCase
    let folderUseCase: any FolderUseCase

    @ObservationIgnored
    private var recentTask: Task<Void, Never>?
    @ObservationIgnored
    private var voiceNoteTask: Task<Void, Never>?
    @ObservationIgnored
    private var myFolderTask: Task<Void, Never>?
    @ObservationIgnored
    private var trashFoldersTask: Task<Void, Never>?
    @ObservationIgnored
    private var trashNotesTask: Task<Void, Never>?

    @ObservationIgnored
    private var trashedFolders: [Folder] = []
    @ObservationIgnored
    private var trashedNotes: [VoiceNote] = []

    // TODO: 화면 전환
    public weak var mainCoordinator: MainCoordinatorDelegate?
    public weak var alertCoordinator: ChaGokAlertCoordinatorDelegate?

    public init(
        microphoneRepository: any VoiceRecordRepository,
        voiceNoteUseCase: any VoiceNoteUseCase,
        folderUseCase: any FolderUseCase
    ) {
        self.microphoneRepository = microphoneRepository
        self.voiceNoteUseCase = voiceNoteUseCase
        self.folderUseCase = folderUseCase
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
        mainCoordinator?.pushVoiceNoteView(voiceNote: voiceNote, isTrashMode: false)
    }

    func presentRecodingView() {
        mainCoordinator?.presentRecodingView()
    }

    func pushSearchView() {
        var uniqueItems: [ContentItem] = []
        var seenIDs: Set<UUID> = []

        let searchableCategories = categoryData.prefix(3)

        for item in searchableCategories.flatMap(\.items) {
            if !seenIDs.contains(item.id) {
                seenIDs.insert(item.id)
                uniqueItems.append(item)
            }
        }

        mainCoordinator?.pushSearchView(
            type: .main,
            items: uniqueItems
        )
    }

    func pushSettingView() {
        mainCoordinator?.pushSettingView()
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
                let stream = try folderUseCase.observeCustom()
                for await folders in stream {
                    categoryData[2].items = folders.map { ContentItem.folder($0) }
                }
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }

    /// 휴지통 관찰 시작 — 삭제된 폴더 + 단독 trashed 노트 stream을 합쳐 emit
    func updateTrashCategory() {
        guard trashFoldersTask == nil, trashNotesTask == nil else { return }
        do {
            let foldersStream = try folderUseCase.observeTrashed()
            let notesStream = try voiceNoteUseCase.observeTrashed()
            trashFoldersTask = Task { [weak self] in
                for await folders in foldersStream {
                    self?.applyTrashedFolders(folders)
                }
            }
            trashNotesTask = Task { [weak self] in
                for await notes in notesStream {
                    self?.applyTrashedNotes(notes)
                }
            }
        } catch {
            AppLogger.error(error)
            errorMessage = error.localizedDescription
        }
    }

    private func applyTrashedFolders(_ folders: [Folder]) {
        trashedFolders = folders
        refreshTrashCategory()
    }

    private func applyTrashedNotes(_ notes: [VoiceNote]) {
        trashedNotes = notes
        refreshTrashCategory()
    }

    private func refreshTrashCategory() {
        categoryData[3].items = trashedFolders.map(ContentItem.folder) + trashedNotes.map(ContentItem.voiceNote)
    }

    /// 관찰 중인 모든 카테고리 stream을 취소합니다.
    func cancelObservations() {
        recentTask?.cancel()
        recentTask = nil
        voiceNoteTask?.cancel()
        voiceNoteTask = nil
        myFolderTask?.cancel()
        myFolderTask = nil
        trashFoldersTask?.cancel()
        trashFoldersTask = nil
        trashNotesTask?.cancel()
        trashNotesTask = nil
    }
}

// MARK: - Mic Permission

extension MainViewModel {
    func handleRecordButtonTap(alertAction: () -> Void) {
        let status = microphoneRepository.checkMicrophonePermission()
        if status != .authorized {
            alertAction()
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
                    defaultItems: previewData.defaultVoiceNotes,
                    trashedItems: previewData.trashedNotes
                ),
                folderUseCase: PreviewFolderUseCase(
                    items: previewData.folders,
                    trashedItems: previewData.trashedFolders
                )
            )

            viewModel.categoryData[0].items = previewData.recentVoiceNotes.map(ContentItem.voiceNote)
            viewModel.categoryData[1].items = previewData.defaultVoiceNotes.map(ContentItem.voiceNote)
            viewModel.categoryData[2].items = previewData.folders.map(ContentItem.folder)
            viewModel.categoryData[3].items = previewData.trashedFolders.map(ContentItem.folder)
                + previewData.trashedNotes.map(ContentItem.voiceNote)
            viewModel.selectedCategoryIndex = max(0, min(selectedCategoryIndex, viewModel.categoryData.count - 1))

            return viewModel
        }
    }

    private extension MainViewModel {
        struct PreviewData {
            let recentVoiceNotes: [VoiceNote]
            let defaultVoiceNotes: [VoiceNote]
            let folders: [Folder]
            let trashedFolders: [Folder]
            let trashedNotes: [VoiceNote]

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

                var trashedFolders: [Folder] = []
                var trashedNotes: [VoiceNote] = []
                for index in 0 ..< 10 {
                    if index.isMultiple(of: 2) {
                        let createdOffset = TimeInterval((index + 2) * 43200) * -1
                        let updatedOffset = TimeInterval((index + 1) * 21600) * -1
                        trashedNotes.append(
                            Self.makeVoiceNote(
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
                        trashedFolders.append(
                            Folder(
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
                    trashedFolders: trashedFolders,
                    trashedNotes: trashedNotes
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
            let trashedItems: [VoiceNote]

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

            func observeTrashed() throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]> {
                let snapshot = trashedItems
                return AsyncStream { continuation in
                    continuation.yield(snapshot)
                    continuation.finish()
                }
            }

            func regenerateSummary(id _: UUID) {}

            func enqueue(id _: UUID) {}

            func moveToTrash(noteID _: UUID) throws(VoiceNoteUseCaseError) {}
            func restore(noteID _: UUID) throws(VoiceNoteUseCaseError) {}
            func delete(noteID _: UUID) throws(VoiceNoteUseCaseError) {}
        }

        struct PreviewFolderUseCase: FolderUseCase {
            let items: [Folder]
            let trashedItems: [Folder]

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

            func observeCustom() throws(FolderUseCaseError) -> AsyncStream<[Folder]> {
                let snapshot = items.filter { $0.kind == .custom }
                return AsyncStream { continuation in
                    continuation.yield(snapshot)
                    continuation.finish()
                }
            }

            func observeTrashed() throws(FolderUseCaseError) -> AsyncStream<[Folder]> {
                let snapshot = trashedItems
                return AsyncStream { continuation in
                    continuation.yield(snapshot)
                    continuation.finish()
                }
            }

            func moveToTrash(folderID _: UUID) throws(FolderUseCaseError) {}
            func restore(folderID _: UUID) throws(FolderUseCaseError) {}
            func delete(folderID _: UUID) throws(FolderUseCaseError) {}
        }
    }
#endif
