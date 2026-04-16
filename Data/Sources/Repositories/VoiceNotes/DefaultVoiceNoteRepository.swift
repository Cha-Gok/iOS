import Core
import Domain
import Foundation

/// VoiceNote 통합 리포지토리 구현체.
public struct DefaultVoiceNoteRepository: VoiceNoteRepository {
    private let store: CoreDataLocalDataBase

    public init(store: CoreDataLocalDataBase) {
        self.store = store
    }

    public func create(_ voiceRecord: VoiceRecord) async throws(VoiceNoteRepositoryError) -> VoiceNote {
        do {
            let defaultFolder = try await fetchDefaultFolder()
            let voiceNote = VoiceNote(
                title: voiceRecord.createdAt.yyyyMMddHHmmssString,
                createdAt: voiceRecord.createdAt,
                updatedAt: voiceRecord.createdAt,
                folderID: defaultFolder.id,
                voiceRecord: voiceRecord
            )
            return try await store.create(voiceNote, as: VoiceNoteEntity.self)
        } catch {
            throw .createFailed
        }
    }

    public func update(_ voiceNote: VoiceNote) async throws(VoiceNoteRepositoryError) -> VoiceNote {
        if Task.isCancelled { throw .cancelled }
        do {
            return try await store.update(voiceNote, as: VoiceNoteEntity.self)
        } catch {
            AppLogger.error(error)
            throw .updateFailed
        }
    }

    public func fetchAllFromDefaultFolder() async throws(VoiceNoteRepositoryError) -> [VoiceNote] {
        if Task.isCancelled { throw .cancelled }

        let folders: [Folder]
        do {
            folders = try await store.fetchAll(FolderEntity.self)
        } catch {
            AppLogger.error(error)
            throw .fetchAllFailed(folderID: nil)
        }

        guard let defaultFolder = folders.first(where: { !$0.isDeletable }) else {
            throw .defaultFolderNotFound
        }

        return try await fetchAll(folderID: defaultFolder.id)
    }

    public func fetchAll(folderID: UUID) async throws(VoiceNoteRepositoryError) -> [VoiceNote] {
        if Task.isCancelled { throw .cancelled }

        do {
            return try await store.fetchAll(VoiceNoteEntity.self)
                .filter { $0.folderID == folderID }
        } catch {
            AppLogger.error(error)
            throw .fetchAllFailed(folderID: folderID)
        }
    }

    public func fetch(byId id: UUID) async throws(VoiceNoteRepositoryError) -> VoiceNote {
        if Task.isCancelled { throw .cancelled }

        do {
            return try await store.fetch(byID: id, as: VoiceNoteEntity.self)
        } catch {
            AppLogger.error(error)
            throw .fetchFailed(id: id)
        }
    }

    public func fetchRecent(limit: Int) async throws(VoiceNoteRepositoryError) -> [VoiceNote] {
        if Task.isCancelled { throw .cancelled }

        do {
            let notes = try await store.fetchAll(VoiceNoteEntity.self)
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

    private func fetchDefaultFolder() async throws(VoiceNoteRepositoryError) -> Folder {
        do {
            let folders = try await store.fetchAll(FolderEntity.self)
            guard let defaultFolder = folders.first(where: { !$0.isDeletable }) else {
                throw VoiceNoteRepositoryError.defaultFolderNotFound
            }
            return defaultFolder
        } catch {
            throw VoiceNoteRepositoryError.defaultFolderNotFound
        }
    }
}
