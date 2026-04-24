import Core
import Foundation

/// 휴지통 통합 유스케이스 프로토콜.
@MainActor
public protocol TrashUseCase: Sendable {
    /// 휴지통 항목 목록을 관찰합니다. 삭제된 폴더 + 단독 삭제된 노트가 합쳐서 emit됩니다.
    func observe() throws(TrashUseCaseError) -> AsyncStream<[WasteBasketItem]>

    /// 노트를 휴지통으로 단독 이동합니다.
    func moveToTrash(noteID: UUID) throws(TrashUseCaseError)

    /// 폴더를 휴지통으로 이동합니다. 안의 노트는 cascade로 휴지통에 함께 이동합니다.
    func moveToTrash(folderID: UUID) throws(TrashUseCaseError)

    /// 노트를 복원합니다.
    func restoreNote(id: UUID) throws(TrashUseCaseError)

    /// 폴더를 복원합니다. cascade 노트도 함께 복원됩니다.
    func restoreFolder(id: UUID) throws(TrashUseCaseError)

    /// 휴지통 항목을 복원합니다.
    func restore(item: WasteBasketItem) throws(TrashUseCaseError)

    /// 여러 항목을 복원합니다.
    func restoreAll(items: [WasteBasketItem]) throws(TrashUseCaseError)

    /// 노트를 영구 삭제합니다.
    func hardDeleteNote(id: UUID) throws(TrashUseCaseError)

    /// 폴더를 영구 삭제합니다. 안의 노트도 cascade로 삭제됩니다.
    func hardDeleteFolder(id: UUID) throws(TrashUseCaseError)

    /// 항목을 영구 삭제합니다.
    func delete(item: WasteBasketItem) throws(TrashUseCaseError)

    /// 여러 항목을 영구 삭제합니다.
    func deleteAll(items: [WasteBasketItem]) throws(TrashUseCaseError)

    /// 휴지통 안의 모든 항목을 영구 삭제합니다.
    func allClear() throws(TrashUseCaseError)
}

public struct DefaultTrashUseCase: TrashUseCase {
    private let voiceNoteRepository: any VoiceNoteRepository
    private let folderRepository: any FolderRepository

    public init(
        voiceNoteRepository: any VoiceNoteRepository,
        folderRepository: any FolderRepository
    ) {
        self.voiceNoteRepository = voiceNoteRepository
        self.folderRepository = folderRepository
    }

    // MARK: - Observe

    public func observe() throws(TrashUseCaseError) -> AsyncStream<[WasteBasketItem]> {
        let foldersStream: AsyncStream<[Folder]>
        let notesStream: AsyncStream<[VoiceNote]>
        do {
            foldersStream = try folderRepository.observeDeleted()
            notesStream = try voiceNoteRepository.observeTrashed()
        } catch let error as FolderRepositoryError {
            AppLogger.error(error)
            throw TrashUseCaseError(error)
        } catch let error as VoiceNoteRepositoryError {
            AppLogger.error(error)
            throw TrashUseCaseError(error)
        } catch {
            AppLogger.error(error)
            throw .unknown(error)
        }

        return AsyncStream { continuation in
            var latestFolders: [Folder] = []
            var latestNotes: [VoiceNote] = []

            let emit: @MainActor () -> Void = {
                let folderItems = latestFolders.map { WasteBasketItem.folder(obj: $0) }
                let noteItems = latestNotes.map { WasteBasketItem.voiceNote(obj: $0) }
                continuation.yield(folderItems + noteItems)
            }

            let foldersTask = Task { @MainActor in
                for await folders in foldersStream {
                    latestFolders = folders
                    emit()
                }
            }
            let notesTask = Task { @MainActor in
                for await notes in notesStream {
                    latestNotes = notes
                    emit()
                }
            }
            continuation.onTermination = { _ in
                foldersTask.cancel()
                notesTask.cancel()
            }
        }
    }

    // MARK: - Move

    public func moveToTrash(noteID: UUID) throws(TrashUseCaseError) {
        let trash = try fetchTrashFolder()
        do {
            try voiceNoteRepository.moveToTrash(id: noteID, trashFolderID: trash.id)
        } catch {
            AppLogger.error(error)
            throw TrashUseCaseError(error)
        }
    }

    public func moveToTrash(folderID: UUID) throws(TrashUseCaseError) {
        let trash = try fetchTrashFolder()
        do {
            try folderRepository.moveToTrash(id: folderID, trashFolderID: trash.id)
        } catch {
            AppLogger.error(error)
            throw TrashUseCaseError(error)
        }
    }

    // MARK: - Restore

    public func restoreNote(id: UUID) throws(TrashUseCaseError) {
        let fallback = try fetchDefaultFolder()
        do {
            try voiceNoteRepository.restore(id: id, fallbackFolderID: fallback.id)
        } catch {
            AppLogger.error(error)
            throw TrashUseCaseError(error)
        }
    }

    public func restoreFolder(id: UUID) throws(TrashUseCaseError) {
        do {
            try folderRepository.restore(id: id)
        } catch {
            AppLogger.error(error)
            throw TrashUseCaseError(error)
        }
    }

    public func restore(item: WasteBasketItem) throws(TrashUseCaseError) {
        switch item {
        case .folder(let folder):
            try restoreFolder(id: folder.id)
        case .voiceNote(let note):
            try restoreNote(id: note.id)
        }
    }

    public func restoreAll(items: [WasteBasketItem]) throws(TrashUseCaseError) {
        for item in items {
            try restore(item: item)
        }
    }

    // MARK: - Hard Delete

    public func hardDeleteNote(id: UUID) throws(TrashUseCaseError) {
        do {
            try voiceNoteRepository.hardDelete(id: id)
        } catch {
            AppLogger.error(error)
            throw TrashUseCaseError(error)
        }
    }

    public func hardDeleteFolder(id: UUID) throws(TrashUseCaseError) {
        do {
            try folderRepository.hardDelete(id: id)
        } catch {
            AppLogger.error(error)
            throw TrashUseCaseError(error)
        }
    }

    public func delete(item: WasteBasketItem) throws(TrashUseCaseError) {
        switch item {
        case .folder(let folder):
            try hardDeleteFolder(id: folder.id)
        case .voiceNote(let note):
            try hardDeleteNote(id: note.id)
        }
    }

    public func deleteAll(items: [WasteBasketItem]) throws(TrashUseCaseError) {
        for item in items {
            try delete(item: item)
        }
    }

    public func allClear() throws(TrashUseCaseError) {
        do {
            let deletedFolders = try folderRepository.fetchAll().filter {
                $0.deletedAt != nil && $0.kind == .custom
            }
            for folder in deletedFolders {
                try folderRepository.hardDelete(id: folder.id)
            }
        } catch {
            AppLogger.error(error)
            throw TrashUseCaseError(error)
        }
        do {
            let trashedNotes = try voiceNoteRepository.fetchTrashed()
            for note in trashedNotes {
                try voiceNoteRepository.hardDelete(id: note.id)
            }
        } catch {
            AppLogger.error(error)
            throw TrashUseCaseError(error)
        }
    }

    // MARK: - Helpers

    private func fetchTrashFolder() throws(TrashUseCaseError) -> Folder {
        let folders: [Folder]
        do {
            folders = try folderRepository.fetch(by: .trash)
        } catch {
            AppLogger.error(error)
            throw TrashUseCaseError(error)
        }
        guard let folder = folders.first else {
            throw TrashUseCaseError(FolderRepositoryError.notFound)
        }
        return folder
    }

    private func fetchDefaultFolder() throws(TrashUseCaseError) -> Folder {
        let folders: [Folder]
        do {
            folders = try folderRepository.fetch(by: .default)
        } catch {
            AppLogger.error(error)
            throw TrashUseCaseError(error)
        }
        guard let folder = folders.first else {
            throw TrashUseCaseError(FolderRepositoryError.notFound)
        }
        return folder
    }
}
