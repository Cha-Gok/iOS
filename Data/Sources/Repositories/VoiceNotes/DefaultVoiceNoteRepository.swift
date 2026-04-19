import Core
import Domain
import Foundation

/// VoiceNote 통합 리포지토리 구현체.
@MainActor
public struct DefaultVoiceNoteRepository: VoiceNoteRepository {
    private let store: CoreDataLocalDataBase

    public init(store: CoreDataLocalDataBase) {
        self.store = store
    }

    public func create(_ voiceRecord: VoiceRecord) throws(VoiceNoteRepositoryError) -> VoiceNote {
        do {
            let defaultFolder = try fetchDefaultFolder()
            let voiceNote = VoiceNote(
                title: voiceRecord.createdAt.yyyyMMddHHmmssString,
                createdAt: voiceRecord.createdAt,
                updatedAt: voiceRecord.createdAt,
                folderID: defaultFolder.id,
                voiceRecord: voiceRecord
            )
            return try store.create(voiceNote, as: VoiceNoteEntity.self)
        } catch {
            throw .createFailed
        }
    }

    public func update(_ voiceNote: VoiceNote) throws(VoiceNoteRepositoryError) -> VoiceNote {
        do {
            return try store.update(voiceNote, as: VoiceNoteEntity.self)
        } catch {
            AppLogger.error(error)
            throw .updateFailed
        }
    }

    public func fetchAllFromDefaultFolder() throws(VoiceNoteRepositoryError) -> [VoiceNote] {
        let folders: [Folder]
        do {
            folders = try store.fetchAll(FolderEntity.self)
        } catch {
            AppLogger.error(error)
            throw .fetchAllFailed(folderID: nil)
        }

        guard let defaultFolder = folders.first(where: { !$0.isDeletable }) else {
            throw .defaultFolderNotFound
        }

        return try fetchAll(folderID: defaultFolder.id)
    }

    public func fetchAll(folderID: UUID) throws(VoiceNoteRepositoryError) -> [VoiceNote] {
        do {
            return try store.fetchAll(VoiceNoteEntity.self)
                .filter { $0.folderID == folderID }
        } catch {
            AppLogger.error(error)
            throw .fetchAllFailed(folderID: folderID)
        }
    }

    public func fetch(byId id: UUID) throws(VoiceNoteRepositoryError) -> VoiceNote {
        do {
            return try store.fetch(byID: id, as: VoiceNoteEntity.self)
        } catch {
            AppLogger.error(error)
            throw .fetchFailed(id: id)
        }
    }

    public func fetchRecent(limit: Int) throws(VoiceNoteRepositoryError) -> [VoiceNote] {
        do {
            let notes = try store.fetchAll(VoiceNoteEntity.self)
            return Array(
                notes.filter { $0.deletedAt == nil }
                    .sorted { $0.createdAt > $1.createdAt }
                    .prefix(limit)
            )
        } catch {
            AppLogger.error(error)
            throw .fetchRecentFailed
        }
    }

    public func observe(id: UUID) throws(VoiceNoteRepositoryError) -> AsyncStream<VoiceNote> {
        do {
            return try store.observe(byID: id, as: VoiceNoteEntity.self)
        } catch {
            AppLogger.error(error)
            throw .fetchFailed(id: id)
        }
    }

    private func fetchDefaultFolder() throws(VoiceNoteRepositoryError) -> Folder {
        do {
            let folders = try store.fetchAll(FolderEntity.self)
            guard let defaultFolder = folders.first(where: { !$0.isDeletable }) else {
                throw VoiceNoteRepositoryError.defaultFolderNotFound
            }
            return defaultFolder
        } catch {
            throw VoiceNoteRepositoryError.defaultFolderNotFound
        }
    }
}
