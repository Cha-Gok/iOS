import Core
import Domain
import Foundation

/// 휴지통 리포지토리 구현체.
/// Soft Delete(`deletedAt` 설정) 및 영구 삭제를 담당합니다.
public struct DefaultWasteBasketRepository: WasteBasketRepository {
    private let store: CoreDataLocalDataBase

    public init(store: CoreDataLocalDataBase) {
        self.store = store
    }

    // MARK: - Fetch

    public func fetchAll() async throws(FetchWasteBasketRepositoryError) -> [WasteBasketItem] {
        if Task.isCancelled { throw .cancelled }

        do {
            async let voiceNoteItems = store.fetchAll(VoiceNoteEntity.self)
                .filter { $0.deletedAt != nil }
                .map { WasteBasketItem.voiceNote(id: $0.id) }

            async let folderItems = store.fetchAll(FolderEntity.self)
                .filter { $0.deletedAt != nil }
                .map { WasteBasketItem.folder(id: $0.id) }

            return try await voiceNoteItems + folderItems
        } catch {
            AppLogger.error(error)
            throw FetchWasteBasketRepositoryError(error)
        }
    }

    // MARK: - Delete

    public func allClear() async throws(DeleteWasteBasketRepositoryError) {
        if Task.isCancelled { throw .cancelled }

        do {
            let voiceNotes = try await store.fetchAll(VoiceNoteEntity.self)
                .filter { $0.deletedAt != nil }
            for voiceNote in voiceNotes {
                _ = try await store.delete(byID: voiceNote.id, as: VoiceNoteEntity.self)
            }

            let folders = try await store.fetchAll(FolderEntity.self)
                .filter { $0.deletedAt != nil }
            for folder in folders {
                _ = try await store.delete(byID: folder.id, as: FolderEntity.self)
            }
        } catch {
            AppLogger.error(error)
            throw .deleteFailed(.all)
        }
    }

    public func delete(item: WasteBasketItem) async throws(DeleteWasteBasketRepositoryError) {
        if Task.isCancelled { throw .cancelled }

        do {
            switch item {
            case .voiceNote(let id):
                _ = try await store.delete(byID: id, as: VoiceNoteEntity.self)
            case .folder(let id):
                _ = try await store.delete(byID: id, as: FolderEntity.self)
            }
        } catch {
            AppLogger.error(error)
            throw .deleteFailed(.single(item: item))
        }
    }

    public func deleteAll(items: [WasteBasketItem]) async throws(DeleteWasteBasketRepositoryError) {
        if Task.isCancelled { throw .cancelled }

        do {
            for item in items {
                switch item {
                case .voiceNote(let id):
                    _ = try await store.delete(byID: id, as: VoiceNoteEntity.self)
                case .folder(let id):
                    _ = try await store.delete(byID: id, as: FolderEntity.self)
                }
            }
        } catch {
            AppLogger.error(error)
            throw .deleteFailed(.multiple(items: items))
        }
    }

    // MARK: - Move

    public func moveToWasteBasket(item: WasteBasketItem) async throws(MoveWasteBasketRepositoryError) {
        if Task.isCancelled { throw .cancelled }

        do {
            switch item {
            case .voiceNote(let id):
                let voiceNote = try await store.fetch(byID: id, as: VoiceNoteEntity.self)
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
                    deletedAt: .now
                )
                _ = try await store.update(updated, as: VoiceNoteEntity.self)

            case .folder(let id):
                let folder = try await store.fetch(byID: id, as: FolderEntity.self)
                let updated = Folder(
                    id: folder.id,
                    name: folder.name,
                    createdAt: folder.createdAt,
                    isDeletable: folder.isDeletable,
                    deletedAt: .now
                )
                _ = try await store.update(updated, as: FolderEntity.self)
            }
        } catch {
            AppLogger.error(error)
            throw .moveFailed(.single(item: item))
        }
    }

    public func moveAllToWasteBasket(items: [WasteBasketItem]) async throws(MoveWasteBasketRepositoryError) {
        if Task.isCancelled { throw .cancelled }

        do {
            for item in items {
                switch item {
                case .voiceNote(let id):
                    let voiceNote = try await store.fetch(byID: id, as: VoiceNoteEntity.self)
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
                        deletedAt: .now
                    )
                    _ = try await store.update(updated, as: VoiceNoteEntity.self)

                case .folder(let id):
                    let folder = try await store.fetch(byID: id, as: FolderEntity.self)
                    let updated = Folder(
                        id: folder.id,
                        name: folder.name,
                        createdAt: folder.createdAt,
                        isDeletable: folder.isDeletable,
                        deletedAt: .now
                    )
                    _ = try await store.update(updated, as: FolderEntity.self)
                }
            }
        } catch {
            AppLogger.error(error)
            throw .moveFailed(.multiple(items: items))
        }
    }

    // MARK: - Restore

    public func restore(item: WasteBasketItem) async throws(RestoreWasteBasketRepositoryError) {
        if Task.isCancelled { throw .cancelled }

        do {
            switch item {
            case .voiceNote(let id):
                let voiceNote = try await store.fetch(byID: id, as: VoiceNoteEntity.self)
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
                    deletedAt: nil
                )
                _ = try await store.update(updated, as: VoiceNoteEntity.self)

            case .folder(let id):
                let folder = try await store.fetch(byID: id, as: FolderEntity.self)
                let updated = Folder(
                    id: folder.id,
                    name: folder.name,
                    createdAt: folder.createdAt,
                    isDeletable: folder.isDeletable,
                    deletedAt: nil
                )
                _ = try await store.update(updated, as: FolderEntity.self)
            }
        } catch {
            AppLogger.error(error)
            throw .restoreFailed(.single(item: item))
        }
    }

    public func restoreAll(items: [WasteBasketItem]) async throws(RestoreWasteBasketRepositoryError) {
        if Task.isCancelled { throw .cancelled }

        do {
            for item in items {
                switch item {
                case .voiceNote(let id):
                    let voiceNote = try await store.fetch(byID: id, as: VoiceNoteEntity.self)
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
                        deletedAt: nil
                    )
                    _ = try await store.update(updated, as: VoiceNoteEntity.self)

                case .folder(let id):
                    let folder = try await store.fetch(byID: id, as: FolderEntity.self)
                    let updated = Folder(
                        id: folder.id,
                        name: folder.name,
                        createdAt: folder.createdAt,
                        isDeletable: folder.isDeletable,
                        deletedAt: nil
                    )
                    _ = try await store.update(updated, as: FolderEntity.self)
                }
            }
        } catch {
            AppLogger.error(error)
            throw .restoreFailed(.multiple(items: items))
        }
    }
}
