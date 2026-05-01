import Core
import Domain
import Foundation

@MainActor
public protocol TrashCoordinatorDelegate: AnyObject {
    /// 뒤로가기
    func pop()
    /// 음성 노트 Push
    func pushVoiceNoteView(voiceNote: VoiceNote)
    /// 상세 폴더 Push
    func pushMyFolderDetailView(_ folder: Folder)
    /// 검색 화면 Push함수
    func pushSearchView(type: SearchViewModel.SearchType, items: [ContentItem])
}

@MainActor
@Observable
public final class TrashViewModel {
    // MARK: - State

    private(set) var items: [ContentItem] = []
    private(set) var errorMessage: String?
    private(set) var select: SelectionMode = .none
    private(set) var selectedItems: [ContentItem] = []
    public weak var coordinator: TrashCoordinatorDelegate?
    public weak var alertCoordinator: ChaGokAlertCoordinatorDelegate?

    @ObservationIgnored
    private var foldersObservationTask: Task<Void, Never>?
    @ObservationIgnored
    private var notesObservationTask: Task<Void, Never>?

    @ObservationIgnored
    private var trashedFolders: [Folder] = []
    @ObservationIgnored
    private var trashedNotes: [VoiceNote] = []

    // MARK: - UseCase

    private let folderUseCase: any FolderUseCase
    private let voiceNoteUseCase: any VoiceNoteUseCase

    // MARK: - Initialize

    public init(
        folderUseCase: any FolderUseCase,
        voiceNoteUseCase: any VoiceNoteUseCase
    ) {
        self.folderUseCase = folderUseCase
        self.voiceNoteUseCase = voiceNoteUseCase
    }
}

// MARK: - Setter / Getter

extension TrashViewModel {
    func setSelectionMode(_ select: SelectionMode) {
        self.select = select
        if select == .none {
            allClearSelected()
        } else if select == .all {
            allSelected()
        }
    }

    private func allSelected() {
        selectedItems = items.compactMap {
            switch $0 {
            case .folder(let folder):
                return .folder(folder)
            case .voiceNote(let voiceNote):
                return .voiceNote(voiceNote)
            }
        }
    }

    private func allClearSelected() {
        selectedItems.removeAll()
    }
}

// MARK: Action

extension TrashViewModel {
    func didTapBack() {
        coordinator?.pop()
    }

    func pushVoiceNote(_ voiceNote: VoiceNote) {
        coordinator?.pushVoiceNoteView(voiceNote: voiceNote)
    }

    func pushDetailFolder(_ folder: Folder) {
        coordinator?.pushMyFolderDetailView(folder)
    }

    func pushSearch() {
        coordinator?.pushSearchView(type: .trash, items: items)
    }

    func selectItem(_ item: ContentItem) {
        if select == .none { setSelectionMode(.multiple) }
        selectedItems.append(item)
    }

    func deselectItem(_ item: ContentItem) {
        selectedItems.removeAll { $0.id == item.id }
    }
    
    func deleteButtonTapped(alertAction: () -> Void) {
        guard !selectedItems.isEmpty else {
            setSelectionMode(.none)
            return
        }
        alertAction()
    }
}

// MARK: - Lifecycle

extension TrashViewModel {
    func onAppear() {
        guard foldersObservationTask == nil, notesObservationTask == nil else { return }
        do {
            let foldersStream = try folderUseCase.observeTrashed()
            let notesStream = try voiceNoteUseCase.observeTrashed()
            foldersObservationTask = Task { [weak self] in
                for await folders in foldersStream {
                    self?.applyTrashedFolders(folders)
                }
            }
            notesObservationTask = Task { [weak self] in
                for await notes in notesStream {
                    self?.applyTrashedNotes(notes)
                }
            }
        } catch {
            AppLogger.error(error)
            errorMessage = error.localizedDescription
        }
    }

    func onDisappear() {
        foldersObservationTask?.cancel()
        foldersObservationTask = nil
        notesObservationTask?.cancel()
        notesObservationTask = nil
    }

    private func applyTrashedFolders(_ folders: [Folder]) {
        trashedFolders = folders
        refreshItems()
    }

    private func applyTrashedNotes(_ notes: [VoiceNote]) {
        trashedNotes = notes
        refreshItems()
    }

    private func refreshItems() {
        items = trashedFolders.map(ContentItem.folder) + trashedNotes.map(ContentItem.voiceNote)
        sortItems()
    }

    private func sortItems() {
        items.sort { lhs, rhs -> Bool in
            let lhsDate = lhs.deletedAt ?? .distantPast
            let rhsDate = rhs.deletedAt ?? .distantPast
            return lhsDate > rhsDate
        }
    }
}

// MARK: - Delete

extension TrashViewModel {
    func deleteAll() {
        do {
            for item in items {
                try deleteOne(item)
            }
            items.removeAll()
            setSelectionMode(.none)
        } catch {
            AppLogger.error(error)
            errorMessage = error.localizedDescription
        }
    }

    func delete(item: ContentItem) {
        do {
            try deleteOne(item)
            items.removeAll { $0.id == item.id }
            setSelectionMode(.none)
        } catch {
            AppLogger.error(error)
            errorMessage = error.localizedDescription
        }
    }

    func delete(items deleteItems: [ContentItem]) {
        do {
            for item in deleteItems {
                try deleteOne(item)
            }
            let deleteIDs = Set(deleteItems.map(\.id))
            items.removeAll { deleteIDs.contains($0.id) }
            setSelectionMode(.none)
        } catch {
            AppLogger.error(error)
            errorMessage = error.localizedDescription
        }
    }

    private func deleteOne(_ item: ContentItem) throws {
        switch item {
        case .folder(let folder):
            try folderUseCase.delete(folderID: folder.id)
        case .voiceNote(let note):
            try voiceNoteUseCase.delete(noteID: note.id)
        }
    }
}

// MARK: - Restore

extension TrashViewModel {
    func restore(item: ContentItem) {
        do {
            try restoreOne(item)
            items.removeAll { $0.id == item.id }
            setSelectionMode(.none)
        } catch {
            AppLogger.error(error)
            errorMessage = error.localizedDescription
        }
    }

    func restore(items restoreItems: [ContentItem]) {
        do {
            for item in restoreItems {
                try restoreOne(item)
            }
            let restoreIDs = Set(restoreItems.map(\.id))
            items.removeAll { restoreIDs.contains($0.id) }
            setSelectionMode(.none)
        } catch {
            AppLogger.error(error)
            errorMessage = error.localizedDescription
        }
    }

    func cancelRestore(item: ContentItem) {
        do {
            try moveToTrashOne(item)
            items.append(item)
            sortItems()
        } catch {
            AppLogger.error(error)
            errorMessage = error.localizedDescription
        }
    }

    func cancelRestore(items restoreItems: [ContentItem]) {
        do {
            for item in restoreItems {
                try moveToTrashOne(item)
            }
            items.append(contentsOf: restoreItems)
            sortItems()
        } catch {
            AppLogger.error(error)
            errorMessage = error.localizedDescription
        }
    }

    private func restoreOne(_ item: ContentItem) throws {
        switch item {
        case .folder(let folder):
            try folderUseCase.restore(folderID: folder.id)
        case .voiceNote(let note):
            try voiceNoteUseCase.restore(noteID: note.id)
        }
    }

    private func moveToTrashOne(_ item: ContentItem) throws {
        switch item {
        case .folder(let folder):
            try folderUseCase.moveToTrash(folderID: folder.id)
        case .voiceNote(let note):
            try voiceNoteUseCase.moveToTrash(noteID: note.id)
        }
    }
}

#if DEBUG
    extension TrashViewModel {
        static func preview() -> TrashViewModel {
            let previewData = PreviewData.make()
            let viewModel = TrashViewModel(
                folderUseCase: PreviewFolderUseCase(trashedFolders: previewData.folders),
                voiceNoteUseCase: PreviewVoiceNoteUseCase(trashedNotes: previewData.notes)
            )
            viewModel.onAppear()
            return viewModel
        }
    }

    private extension TrashViewModel {
        struct PreviewData {
            let folders: [Folder]
            let notes: [VoiceNote]

            static func make(now: Date = .now) -> Self {
                var folders: [Folder] = []
                var notes: [VoiceNote] = []
                for index in 0 ..< 10 {
                    if index.isMultiple(of: 2) {
                        let createdOffset = TimeInterval((index + 2) * 43200) * -1
                        let updatedOffset = TimeInterval((index + 1) * 21600) * -1
                        let deletedOffset = TimeInterval((index + 1) * 10800) * -1

                        notes.append(
                            VoiceNote(
                                title: "휴지통 메모 \(index + 1)",
                                createdAt: now.addingTimeInterval(createdOffset),
                                updatedAt: now.addingTimeInterval(updatedOffset),
                                folderID: UUID(),
                                voiceRecord: VoiceRecord(
                                    createdAt: now.addingTimeInterval(createdOffset),
                                    audioFilePath: "VoiceRecords/preview-\(index).m4a",
                                    duration: Double(120 + index * 15)
                                ),
                                transcript: nil,
                                summary: nil,
                                deletedAt: now.addingTimeInterval(deletedOffset),
                                analysisState: .pending
                            )
                        )
                    } else {
                        let createdOffset = TimeInterval((index + 1) * 64800) * -1
                        let deletedOffset = TimeInterval((index + 1) * 10800) * -1
                        folders.append(
                            Folder(
                                name: "휴지통 폴더 \(index + 1)",
                                createdAt: now.addingTimeInterval(createdOffset),
                                kind: .custom,
                                deletedAt: now.addingTimeInterval(deletedOffset)
                            )
                        )
                    }
                }
                return PreviewData(folders: folders, notes: notes)
            }
        }

        struct PreviewFolderUseCase: FolderUseCase {
            let trashedFolders: [Folder]

            func create(name: String) throws(FolderUseCaseError) -> Folder {
                Folder(name: name, kind: .custom)
            }

            func createDefault() throws(FolderUseCaseError) -> Folder {
                Folder(name: "기본 폴더", kind: .default)
            }

            func createTrash() throws(FolderUseCaseError) -> Folder {
                Folder(name: "휴지통", kind: .trash)
            }

            func fetchAll() throws(FolderUseCaseError) -> [Folder] {
                []
            }

            func fetchDefault() throws(FolderUseCaseError) -> Folder {
                Folder(name: "기본 폴더", kind: .default)
            }

            func fetchTrash() throws(FolderUseCaseError) -> Folder {
                Folder(name: "휴지통", kind: .trash)
            }

            func fetchDeletableFolders() throws(FolderUseCaseError) -> [Folder] {
                []
            }

            func fetch(by _: UUID) throws(FolderUseCaseError) -> Folder {
                Folder(name: "기본 폴더", kind: .default)
            }

            func update(_ folder: Folder) throws(FolderUseCaseError) -> Folder {
                folder
            }

            func observeCustom() throws(FolderUseCaseError) -> AsyncStream<[Folder]> {
                AsyncStream { $0.finish() }
            }

            func observeTrashed() throws(FolderUseCaseError) -> AsyncStream<[Folder]> {
                let snapshot = trashedFolders
                return AsyncStream { continuation in
                    continuation.yield(snapshot)
                    continuation.finish()
                }
            }

            func moveToTrash(folderID _: UUID) throws(FolderUseCaseError) {}
            func restore(folderID _: UUID) throws(FolderUseCaseError) {}
            func delete(folderID _: UUID) throws(FolderUseCaseError) {}
        }

        struct PreviewVoiceNoteUseCase: VoiceNoteUseCase {
            let trashedNotes: [VoiceNote]

            func create(_ voiceRecord: VoiceRecord) throws(VoiceNoteUseCaseError) -> VoiceNote {
                VoiceNote(title: "미리보기", folderID: UUID(), voiceRecord: voiceRecord, analysisState: .pending)
            }

            func fetch(byId id: UUID) throws(VoiceNoteUseCaseError) -> VoiceNote {
                throw .recordNotFound(id)
            }

            func update(_ voiceNote: VoiceNote) throws(VoiceNoteUseCaseError) -> VoiceNote {
                voiceNote
            }

            func observe(id: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<VoiceNote> {
                AsyncStream { $0.finish() }
            }

            func observe(folderID _: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]> {
                AsyncStream { $0.finish() }
            }

            func observeRecent(limit _: Int) throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]> {
                AsyncStream { $0.finish() }
            }

            func observeTrashed() throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]> {
                let snapshot = trashedNotes
                return AsyncStream { continuation in
                    continuation.yield(snapshot)
                    continuation.finish()
                }
            }

            func regenerateSummary(id _: UUID) {}
            func moveToTrash(noteID _: UUID) throws(VoiceNoteUseCaseError) {}
            func restore(noteID _: UUID) throws(VoiceNoteUseCaseError) {}
            func delete(noteID _: UUID) throws(VoiceNoteUseCaseError) {}
        }
    }
#endif
