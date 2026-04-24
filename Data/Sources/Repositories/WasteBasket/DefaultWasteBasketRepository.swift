import Core
import Domain
import Foundation

/// 휴지통 리포지토리 구현체.
/// Soft Delete(`deletedAt` 설정) 및 영구 삭제를 담당합니다.
@MainActor
public struct DefaultWasteBasketRepository: WasteBasketRepository {
    private let store: CoreDataLocalDataBase

    public init(store: CoreDataLocalDataBase) {
        self.store = store
    }

    // MARK: - Fetch

    public func fetchAll() throws(FetchWasteBasketRepositoryError) -> [WasteBasketItem] {
        do {
            let voiceNoteItems = try store.fetchAll(VoiceNoteEntity.self)
                .filter { $0.deletedAt != nil }
                .map { WasteBasketItem.voiceNote(obj: $0) }

            let folderItems = try store.fetchAll(FolderEntity.self)
                .filter { $0.deletedAt != nil }
                .map { WasteBasketItem.folder(obj: $0) }

            return voiceNoteItems + folderItems
        } catch {
            AppLogger.error(error)
            throw FetchWasteBasketRepositoryError(error)
        }
    }

    public func observe() throws(FetchWasteBasketRepositoryError) -> AsyncStream<[WasteBasketItem]> {
        let voiceNoteStream: AsyncStream<[VoiceNote]>
        let folderStream: AsyncStream<[Folder]>
        do {
            voiceNoteStream = try store.observeAll(VoiceNoteEntity.self)
            folderStream = try store.observeAll(FolderEntity.self)
        } catch {
            AppLogger.error(error)
            throw FetchWasteBasketRepositoryError(error)
        }

        return AsyncStream { continuation in
            let voiceNoteTask = Task { @MainActor in
                for await _ in voiceNoteStream {
                    if let snapshot = try? fetchAll() {
                        continuation.yield(snapshot)
                    }
                }
            }
            let folderTask = Task { @MainActor in
                for await _ in folderStream {
                    if let snapshot = try? fetchAll() {
                        continuation.yield(snapshot)
                    }
                }
            }
            continuation.onTermination = { _ in
                voiceNoteTask.cancel()
                folderTask.cancel()
            }
        }
    }

    // MARK: - Delete

    public func allClear() throws(DeleteWasteBasketRepositoryError) {
        do {
            let voiceNotes = try store.fetchAll(VoiceNoteEntity.self)
                .filter { $0.deletedAt != nil }
            for voiceNote in voiceNotes {
                _ = try store.delete(byID: voiceNote.id, as: VoiceNoteEntity.self)
            }

            let folders = try store.fetchAll(FolderEntity.self)
                .filter { $0.deletedAt != nil }
            for folder in folders {
                _ = try store.delete(byID: folder.id, as: FolderEntity.self)
            }
        } catch {
            AppLogger.error(error)
            throw .deleteFailed(.all)
        }
    }

    public func delete(item: WasteBasketItem) throws(DeleteWasteBasketRepositoryError) {
        do {
            switch item {
            case .voiceNote(let obj):
                _ = try store.delete(byID: obj.id, as: VoiceNoteEntity.self)
            case .folder(let obj):
                _ = try store.delete(byID: obj.id, as: FolderEntity.self)
            }
        } catch {
            AppLogger.error(error)
            throw .deleteFailed(.single(item: item))
        }
    }

    public func deleteAll(items: [WasteBasketItem]) throws(DeleteWasteBasketRepositoryError) {
        do {
            for item in items {
                switch item {
                case .voiceNote(let obj):
                    _ = try store.delete(byID: obj.id, as: VoiceNoteEntity.self)
                case .folder(let obj):
                    _ = try store.delete(byID: obj.id, as: FolderEntity.self)
                }
            }
        } catch {
            AppLogger.error(error)
            throw .deleteFailed(.multiple(items: items))
        }
    }

    // MARK: - Move

    public func moveToWasteBasket(item: WasteBasketItem) throws(MoveWasteBasketRepositoryError) {
        do {
            switch item {
            case .voiceNote(let obj):
                let voiceNote = try store.fetch(byID: obj.id, as: VoiceNoteEntity.self)
                let updated = VoiceNote(
                    id: voiceNote.id,
                    title: voiceNote.title,
                    createdAt: voiceNote.createdAt,
                    updatedAt: .now,
                    folderID: voiceNote.folderID,
                    voiceRecord: voiceNote.voiceRecord,
                    keywords: voiceNote.keywords,
                    transcript: voiceNote.transcript,
                    summary: voiceNote.summary,
                    deletedAt: .now,
                    analysisState: voiceNote.analysisState
                )
                _ = try store.update(updated, as: VoiceNoteEntity.self)

            case .folder(let obj):
                let folder = try store.fetch(byID: obj.id, as: FolderEntity.self)
                let updated = Folder(
                    id: folder.id,
                    name: folder.name,
                    createdAt: folder.createdAt,
                    isDeletable: folder.isDeletable,
                    deletedAt: .now
                )
                _ = try store.update(updated, as: FolderEntity.self)
            }
        } catch {
            AppLogger.error(error)
            throw .moveFailed(.single(item: item))
        }
    }

    public func moveAllToWasteBasket(items: [WasteBasketItem]) throws(MoveWasteBasketRepositoryError) {
        do {
            for item in items {
                switch item {
                case .voiceNote(let obj):
                    let voiceNote = try store.fetch(byID: obj.id, as: VoiceNoteEntity.self)
                    let updated = VoiceNote(
                        id: voiceNote.id,
                        title: voiceNote.title,
                        createdAt: voiceNote.createdAt,
                        updatedAt: .now,
                        folderID: voiceNote.folderID,
                        voiceRecord: voiceNote.voiceRecord,
                        keywords: voiceNote.keywords,
                        transcript: voiceNote.transcript,
                        summary: voiceNote.summary,
                        deletedAt: .now,
                        analysisState: voiceNote.analysisState
                    )
                    _ = try store.update(updated, as: VoiceNoteEntity.self)

                case .folder(let obj):
                    let folder = try store.fetch(byID: obj.id, as: FolderEntity.self)
                    let updated = Folder(
                        id: folder.id,
                        name: folder.name,
                        createdAt: folder.createdAt,
                        isDeletable: folder.isDeletable,
                        deletedAt: .now
                    )
                    _ = try store.update(updated, as: FolderEntity.self)
                }
            }
        } catch {
            AppLogger.error(error)
            throw .moveFailed(.multiple(items: items))
        }
    }

    // MARK: - Restore

    public func restore(item: WasteBasketItem) throws(RestoreWasteBasketRepositoryError) {
        do {
            switch item {
            case .voiceNote(let obj):
                let voiceNote = try store.fetch(byID: obj.id, as: VoiceNoteEntity.self)
                let updated = VoiceNote(
                    id: voiceNote.id,
                    title: voiceNote.title,
                    createdAt: voiceNote.createdAt,
                    updatedAt: .now,
                    folderID: voiceNote.folderID,
                    voiceRecord: voiceNote.voiceRecord,
                    keywords: voiceNote.keywords,
                    transcript: voiceNote.transcript,
                    summary: voiceNote.summary,
                    deletedAt: nil,
                    analysisState: voiceNote.analysisState
                )
                _ = try store.update(updated, as: VoiceNoteEntity.self)

            case .folder(let obj):
                let folder = try store.fetch(byID: obj.id, as: FolderEntity.self)
                let updated = Folder(
                    id: folder.id,
                    name: folder.name,
                    createdAt: folder.createdAt,
                    isDeletable: folder.isDeletable,
                    deletedAt: nil
                )
                _ = try store.update(updated, as: FolderEntity.self)
            }
        } catch {
            AppLogger.error(error)
            throw .restoreFailed(.single(item: item))
        }
    }

    public func restoreAll(items: [WasteBasketItem]) throws(RestoreWasteBasketRepositoryError) {
        do {
            for item in items {
                switch item {
                case .voiceNote(let obj):
                    let voiceNote = try store.fetch(byID: obj.id, as: VoiceNoteEntity.self)
                    let updated = VoiceNote(
                        id: voiceNote.id,
                        title: voiceNote.title,
                        createdAt: voiceNote.createdAt,
                        updatedAt: .now,
                        folderID: voiceNote.folderID,
                        voiceRecord: voiceNote.voiceRecord,
                        keywords: voiceNote.keywords,
                        transcript: voiceNote.transcript,
                        summary: voiceNote.summary,
                        deletedAt: nil,
                        analysisState: voiceNote.analysisState
                    )
                    _ = try store.update(updated, as: VoiceNoteEntity.self)

                case .folder(let obj):
                    let folder = try store.fetch(byID: obj.id, as: FolderEntity.self)
                    let updated = Folder(
                        id: folder.id,
                        name: folder.name,
                        createdAt: folder.createdAt,
                        isDeletable: folder.isDeletable,
                        deletedAt: nil
                    )
                    _ = try store.update(updated, as: FolderEntity.self)
                }
            }
        } catch {
            AppLogger.error(error)
            throw .restoreFailed(.multiple(items: items))
        }
    }
}
