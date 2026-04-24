import Core
import CoreData
import Domain
import Foundation

/// VoiceNote 통합 리포지토리 구현체.
@MainActor
public struct DefaultVoiceNoteRepository: VoiceNoteRepository {
    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    public func create(_ voiceNote: VoiceNote) throws(VoiceNoteRepositoryError) -> VoiceNote {
        let folderRequest = NSFetchRequest<FolderEntity>(entityName: CoreDataEntityName.folder.rawValue)
        folderRequest.predicate = NSPredicate(format: "id == %@", voiceNote.folderID as CVarArg)
        folderRequest.fetchLimit = 1

        let folderEntity: FolderEntity
        do {
            guard let found = try context.fetch(folderRequest).first else {
                throw VoiceNoteRepositoryError.defaultFolderNotFound
            }
            folderEntity = found
        } catch let error as VoiceNoteRepositoryError {
            throw error
        } catch {
            AppLogger.error(error)
            throw .createFailed
        }

        let recordEntity = VoiceRecordEntity(context: context)
        recordEntity.id = voiceNote.voiceRecord.id
        recordEntity.audioFilePath = voiceNote.voiceRecord.audioFilePath
        recordEntity.duration = voiceNote.voiceRecord.duration
        recordEntity.createdAt = voiceNote.voiceRecord.createdAt

        let noteEntity = VoiceNoteEntity(context: context)
        noteEntity.id = voiceNote.id
        noteEntity.title = voiceNote.title
        noteEntity.createdAt = voiceNote.createdAt
        noteEntity.updatedAt = voiceNote.updatedAt
        noteEntity.deletedAt = voiceNote.deletedAt
        noteEntity.analysisStateRaw = voiceNote.analysisState.rawValue
        noteEntity.folder = folderEntity
        noteEntity.voiceRecord = recordEntity
        recordEntity.voiceNote = noteEntity

        do {
            try context.save()
        } catch {
            AppLogger.error(error)
            throw .createFailed
        }

        return voiceNote
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

        guard let defaultFolder = folders.first(where: { $0.kind == .default }) else {
            throw .defaultFolderNotFound
        }

        return try fetchAll(folderID: defaultFolder.id)
    }

    public func fetchAll(folderID: UUID) throws(VoiceNoteRepositoryError) -> [VoiceNote] {
        do {
            return try store.fetch(
                VoiceNoteEntity.self,
                where: NSPredicate(format: "folder.id == %@", folderID as CVarArg)
            )
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
            return try store.fetch(
                VoiceNoteEntity.self,
                where: NSPredicate(format: "deletedAt == nil"),
                sortedBy: [NSSortDescriptor(keyPath: \VoiceNoteEntity.createdAt, ascending: false)],
                limit: limit
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

    public func observeAllFromDefaultFolder() throws(VoiceNoteRepositoryError) -> AsyncStream<[VoiceNote]> {
        let defaultFolder = try fetchDefaultFolder()
        return try observe(folderID: defaultFolder.id)
    }

    public func observe(folderID: UUID) throws(VoiceNoteRepositoryError) -> AsyncStream<[VoiceNote]> {
        do {
            return try store.observeAll(
                VoiceNoteEntity.self,
                where: NSPredicate(format: "folder.id == %@", folderID as CVarArg)
            )
        } catch {
            AppLogger.error(error)
            throw .fetchAllFailed(folderID: folderID)
        }
    }

    public func observeRecent(limit: Int) throws(VoiceNoteRepositoryError) -> AsyncStream<[VoiceNote]> {
        do {
            return try store.observeAll(
                VoiceNoteEntity.self,
                where: NSPredicate(format: "deletedAt == nil"),
                sortedBy: [NSSortDescriptor(keyPath: \VoiceNoteEntity.createdAt, ascending: false)],
                limit: limit
            )
        } catch {
            AppLogger.error(error)
            throw .fetchRecentFailed
        }
    }

    private func fetchDefaultFolder() throws(VoiceNoteRepositoryError) -> Folder {
        do {
            let folders = try store.fetchAll(FolderEntity.self)
            guard let defaultFolder = folders.first(where: { $0.kind == .default }) else {
                throw VoiceNoteRepositoryError.defaultFolderNotFound
            }
            return defaultFolder
        } catch {
            throw VoiceNoteRepositoryError.defaultFolderNotFound
        }
    }
}
