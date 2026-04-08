import Core
import Domain
import Foundation

/// VoiceNote 조회 리포지토리 구현체.
public struct DefaultVoiceNoteFetchRepository: VoiceNoteFetchRepository {
    private let store: CoreDataLocalDataBase

    public init(store: CoreDataLocalDataBase) {
        self.store = store
    }

    public func fetchAllFromDefaultFolder() async throws(VoiceNoteFetchRepositoryError) -> [VoiceNote] {
        if Task.isCancelled { throw .cancelled }

        let folders: [Folder]
        do {
            folders = try await store.fetchAll(FolderEntity.self)
        } catch {
            AppLogger.error(error)
            throw VoiceNoteFetchRepositoryError(error)
        }

        guard let defaultFolder = folders.first(where: { !$0.isDeletable }) else {
            throw .defaultFolderNotFound
        }

        return try await fetchAll(folderID: defaultFolder.id)
    }

    public func fetchAll(folderID: UUID) async throws(VoiceNoteFetchRepositoryError) -> [VoiceNote] {
        if Task.isCancelled { throw .cancelled }

        do {
            return try await store.fetchAll(VoiceNoteEntity.self)
                .filter { $0.folderID == folderID }
        } catch {
            AppLogger.error(error)
            throw .fetchAllFailed(folderID: folderID)
        }
    }

    public func fetch(byId id: UUID) async throws(VoiceNoteFetchRepositoryError) -> VoiceNote {
        if Task.isCancelled { throw .cancelled }

        do {
            return try await store.fetch(byID: id, as: VoiceNoteEntity.self)
        } catch {
            AppLogger.error(error)
            throw .fetchFailed(id: id)
        }
    }

    public func fetchRecent(limit: Int) async throws(VoiceNoteFetchRepositoryError) -> [VoiceNote] {
        if Task.isCancelled { throw .cancelled }

        do {
            return try await store.fetchAll(VoiceNoteEntity.self)
                .filter { $0.deletedAt == nil }
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(limit)
                .map(\.self)
        } catch {
            AppLogger.error(error)
            throw .fetchRecentFailed
        }
    }
}
