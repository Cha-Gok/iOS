import Core
import Domain
import Foundation

@MainActor
public protocol TrashCoordinatorDelegate: AnyObject {
    func pop()
    func pushVoiceNoteView(voiceNote: VoiceNote)
    func pushMyFolderDetailView(_ folder: Folder)
}

@MainActor
@Observable
public final class TrashViewModel {
    // MARK: - State

    private(set) var items: [LibraryItem] = []
    private(set) var errorMessage: String?
    private(set) var select: SelectionMode = .none
    private(set) var selectedItems: [WasteBasketItem] = []
    private(set) var showTrashAlert: Bool = false

    public weak var coordinator: TrashCoordinatorDelegate?

    @ObservationIgnored
    private var observationTask: Task<Void, Never>?

    // MARK: - UseCase

    private let trashUseCase: any TrashUseCase
    private let folderUseCase: any FolderUseCase
    private let voiceNoteUseCase: any VoiceNoteUseCase

    // MARK: - Initialize

    public init(
        trashUseCase: any TrashUseCase,
        folderUseCase: any FolderUseCase,
        voiceNoteUseCase: any VoiceNoteUseCase
    ) {
        self.trashUseCase = trashUseCase
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
                return .folder(obj: folder)
            case .voiceNote(let voiceNote):
                return .voiceNote(obj: voiceNote)
            }
        }
    }

    private func allClearSelected() {
        selectedItems.removeAll()
    }

    func openTrashAlert() {
        showTrashAlert = true
    }

    func closeTrashAlert() {
        showTrashAlert = false
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

    func selectItem(_ item: WasteBasketItem) {
        if select == .none { setSelectionMode(.multiple) }
        selectedItems.append(item)
    }

    func deselectItem(_ item: WasteBasketItem) {
        selectedItems.removeAll { $0.id == item.id }
    }
}

// MARK: - Lifecycle

extension TrashViewModel {
    func onAppear() {
        guard observationTask == nil else { return }
        observationTask = Task { [weak self] in
            guard let self else { return }
            do {
                let stream = try trashUseCase.observe()
                for await wasteBaskets in stream {
                    items = wasteBaskets.map(\.toLibraryItem)
                    sortItems()
                }
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }

    func onDisappear() {
        observationTask?.cancel()
        observationTask = nil
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
            try trashUseCase.allClear()
            items.removeAll()
            setSelectionMode(.none)
        } catch {
            AppLogger.error(error)
            errorMessage = error.localizedDescription
        }
    }

    func delete(item: WasteBasketItem) {
        do {
            try deleteOne(item)
            items.removeAll { $0.id == item.id }
            setSelectionMode(.none)
        } catch {
            AppLogger.error(error)
            errorMessage = error.localizedDescription
        }
    }

    func delete(items deleteItems: [WasteBasketItem]) {
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

    private func deleteOne(_ item: WasteBasketItem) throws {
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
    func restore(item: WasteBasketItem) {
        do {
            try restoreOne(item)
            items.removeAll { $0.id == item.id }
            setSelectionMode(.none)
        } catch {
            AppLogger.error(error)
            errorMessage = error.localizedDescription
        }
    }

    func restore(items restoreItems: [WasteBasketItem]) {
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

    func cancelRestore(item: WasteBasketItem) {
        do {
            try moveToTrashOne(item)
            items.append(item.toLibraryItem)
            sortItems()
        } catch {
            AppLogger.error(error)
            errorMessage = error.localizedDescription
        }
    }

    func cancelRestore(items restoreItems: [WasteBasketItem]) {
        do {
            for item in restoreItems {
                try moveToTrashOne(item)
            }
            items.append(contentsOf: restoreItems.map(\.toLibraryItem))
            sortItems()
        } catch {
            AppLogger.error(error)
            errorMessage = error.localizedDescription
        }
    }

    private func restoreOne(_ item: WasteBasketItem) throws {
        switch item {
        case .folder(let folder):
            try folderUseCase.restore(folderID: folder.id)
        case .voiceNote(let note):
            try voiceNoteUseCase.restore(noteID: note.id)
        }
    }

    private func moveToTrashOne(_ item: WasteBasketItem) throws {
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
                trashUseCase: PreviewTrashUseCase(items: previewData.items),
                folderUseCase: PreviewFolderUseCase(),
                voiceNoteUseCase: PreviewVoiceNoteUseCase()
            )
            viewModel.onAppear()
            return viewModel
        }
    }

    private extension TrashViewModel {
        struct PreviewData {
            let items: [WasteBasketItem]

            static func make(now: Date = .now) -> Self {
                let items: [WasteBasketItem] = (0 ..< 10).map { index in
                    if index.isMultiple(of: 2) {
                        let createdOffset = TimeInterval((index + 2) * 43200) * -1
                        let updatedOffset = TimeInterval((index + 1) * 21600) * -1

                        return .voiceNote(
                            obj: VoiceNote(
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
                                analysisState: .pending
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
                return PreviewData(items: items)
            }
        }

        struct PreviewFolderUseCase: FolderUseCase {
            func create(name: String) throws(FolderUseCaseError) -> Folder {
                Folder(name: name, kind: .custom)
            }

            func createDefault() throws(FolderUseCaseError) -> Folder {
                Folder(name: "기본 폴더", kind: .default)
            }

            func createTrash() throws(FolderUseCaseError) -> Folder {
                Folder(name: "휴지통", kind: .trash)
            }

            func fetchAll() throws(FolderUseCaseError) -> [Folder] { [] }
            func fetchDefault() throws(FolderUseCaseError) -> Folder {
                Folder(name: "기본 폴더", kind: .default)
            }

            func fetchTrash() throws(FolderUseCaseError) -> Folder {
                Folder(name: "휴지통", kind: .trash)
            }

            func fetchDeletableFolders() throws(FolderUseCaseError) -> [Folder] { [] }
            func fetch(by _: UUID) throws(FolderUseCaseError) -> Folder {
                Folder(name: "기본 폴더", kind: .default)
            }

            func update(_ folder: Folder) throws(FolderUseCaseError) -> Folder { folder }

            func observeDeletableFolders() throws(FolderUseCaseError) -> AsyncStream<[Folder]> {
                AsyncStream { $0.finish() }
            }

            func moveToTrash(folderID _: UUID) throws(FolderUseCaseError) {}
            func restore(folderID _: UUID) throws(FolderUseCaseError) {}
            func delete(folderID _: UUID) throws(FolderUseCaseError) {}
        }

        struct PreviewVoiceNoteUseCase: VoiceNoteUseCase {
            func create(_ voiceRecord: VoiceRecord) throws(VoiceNoteUseCaseError) -> VoiceNote {
                VoiceNote(title: "미리보기", folderID: UUID(), voiceRecord: voiceRecord, analysisState: .pending)
            }

            func fetch(byId id: UUID) throws(VoiceNoteUseCaseError) -> VoiceNote {
                throw .recordNotFound(id)
            }

            func update(_ voiceNote: VoiceNote) throws(VoiceNoteUseCaseError) -> VoiceNote { voiceNote }

            func observe(id: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<VoiceNote> {
                AsyncStream { $0.finish() }
            }

            func observe(folderID _: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]> {
                AsyncStream { $0.finish() }
            }

            func observeRecent(limit _: Int) throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]> {
                AsyncStream { $0.finish() }
            }

            func regenerateSummary(id _: UUID) {}
            func moveToTrash(noteID _: UUID) throws(VoiceNoteUseCaseError) {}
            func restore(noteID _: UUID) throws(VoiceNoteUseCaseError) {}
            func delete(noteID _: UUID) throws(VoiceNoteUseCaseError) {}
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
    }
#endif
