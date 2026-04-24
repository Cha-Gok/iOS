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
        do {
            let folderRequest = FolderEntity.fetchRequest()
            folderRequest.predicate = NSPredicate(format: "id == %@", voiceNote.folderID as CVarArg)
            folderRequest.fetchLimit = 1
            guard let folderEntity = try context.fetch(folderRequest).first else {
                throw VoiceNoteRepositoryError.defaultFolderNotFound
            }

            let voiceRecordEntity = VoiceRecordEntity(model: voiceNote.voiceRecord, context: context)
            let voiceNoteEntity = VoiceNoteEntity(model: voiceNote, context: context)
            voiceNoteEntity.folder = folderEntity
            voiceNoteEntity.voiceRecord = voiceRecordEntity
            voiceRecordEntity.voiceNote = voiceNoteEntity

            try context.save()
            return voiceNote
        } catch {
            AppLogger.error(error)
            throw .createFailed
        }
    }

    public func update(_ voiceNote: VoiceNote) throws(VoiceNoteRepositoryError) -> VoiceNote {
        do {
            // 1. 대상 entity 찾기
            let request = VoiceNoteEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", voiceNote.id as CVarArg)
            request.fetchLimit = 1
            guard let voiceNoteEntity = try context.fetch(request).first else {
                throw VoiceNoteRepositoryError.fetchFailed(id: voiceNote.id)
            }

            // 2. scalar + voiceRecord 갱신
            voiceNoteEntity.update(from: voiceNote)
            voiceNoteEntity.voiceRecord.update(from: voiceNote.voiceRecord)

            // 3. folder set (항상 갱신)
            let folderRequest = FolderEntity.fetchRequest()
            folderRequest.predicate = NSPredicate(format: "id == %@", voiceNote.folderID as CVarArg)
            folderRequest.fetchLimit = 1
            guard let folderEntity = try context.fetch(folderRequest).first else {
                throw VoiceNoteRepositoryError.defaultFolderNotFound
            }
            voiceNoteEntity.folder = folderEntity

            // 4. transcript 동기화
            switch (voiceNote.transcript, voiceNoteEntity.transcript) {
            case (let model?, let entity?):
                entity.update(from: model)
            case (let model?, nil):
                let new = TranscriptEntity(model: model, context: context)
                new.voiceNote = voiceNoteEntity
                voiceNoteEntity.transcript = new
            case (nil, let old?):
                context.delete(old)
                voiceNoteEntity.transcript = nil
            case (nil, nil):
                break
            }

            // 5. summary 동기화
            switch (voiceNote.summary, voiceNoteEntity.summary) {
            case (let model?, let entity?):
                entity.update(from: model)
            case (let model?, nil):
                let new = SummaryEntity(model: model, context: context)
                new.voiceNote = voiceNoteEntity
                voiceNoteEntity.summary = new
            case (nil, let old?):
                context.delete(old)
                voiceNoteEntity.summary = nil
            case (nil, nil):
                break
            }

            // 6. keywords 덮어쓰기 (기존 삭제 후 새로 생성)
            for entity in (voiceNoteEntity.keywords as? Set<KeywordEntity>) ?? [] {
                context.delete(entity)
            }
            for keywordModel in voiceNote.keywords {
                let new = KeywordEntity(model: keywordModel, context: context)
                new.voiceNote = voiceNoteEntity
            }

            try context.save()
            return voiceNoteEntity.toModel()
        } catch {
            AppLogger.error(error)
            throw .updateFailed
        }
    }

    public func fetch(byId id: UUID) throws(VoiceNoteRepositoryError) -> VoiceNote {
        do {
            let request = VoiceNoteEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            guard let entity = try context.fetch(request).first else {
                throw VoiceNoteRepositoryError.fetchFailed(id: id)
            }
            return entity.toModel()
        } catch {
            AppLogger.error(error)
            throw .fetchFailed(id: id)
        }
    }

    public func observe(id: UUID) throws(VoiceNoteRepositoryError) -> AsyncStream<VoiceNote> {
        let request = VoiceNoteEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \VoiceNoteEntity.createdAt, ascending: false)]
        request.fetchLimit = 1

        let frc = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        do {
            try frc.performFetch()
            guard let initial = frc.fetchedObjects?.first else {
                throw VoiceNoteRepositoryError.fetchFailed(id: id)
            }

            nonisolated(unsafe) let sendableFRC = frc

            return AsyncStream { continuation in
                continuation.yield(initial.toModel())

                let delegate = FRCStreamDelegate {
                    if let entity = frc.fetchedObjects?.first {
                        continuation.yield(entity.toModel())
                    } else {
                        continuation.finish()
                    }
                }
                frc.delegate = delegate

                continuation.onTermination = { _ in
                    sendableFRC.delegate = nil
                    _ = delegate
                }
            }
        } catch {
            AppLogger.error(error)
            throw .fetchFailed(id: id)
        }
    }

    public func observe(folderID: UUID) throws(VoiceNoteRepositoryError) -> AsyncStream<[VoiceNote]> {
        let request = VoiceNoteEntity.fetchRequest()
        request.predicate = NSPredicate(format: "folder.id == %@ AND deletedAt == nil", folderID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \VoiceNoteEntity.createdAt, ascending: false)]
        return try makeListStream(request: request) { .fetchAllFailed(folderID: folderID) }
    }

    public func observeRecent(limit: Int) throws(VoiceNoteRepositoryError) -> AsyncStream<[VoiceNote]> {
        let request = VoiceNoteEntity.fetchRequest()
        request.predicate = NSPredicate(format: "deletedAt == nil AND folder.parentID == nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \VoiceNoteEntity.createdAt, ascending: false)]
        request.fetchLimit = limit
        return try makeListStream(request: request) { .fetchRecentFailed }
    }

    public func observeTrashed() throws(VoiceNoteRepositoryError) -> AsyncStream<[VoiceNote]> {
        let request = VoiceNoteEntity.fetchRequest()
        request.predicate = NSPredicate(format: "deletedAt != nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \VoiceNoteEntity.deletedAt, ascending: false)]
        return try makeListStream(request: request) { .fetchRecentFailed }
    }

    public func fetchTrashed() throws(VoiceNoteRepositoryError) -> [VoiceNote] {
        do {
            let request = VoiceNoteEntity.fetchRequest()
            request.predicate = NSPredicate(format: "deletedAt != nil")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \VoiceNoteEntity.deletedAt, ascending: false)]
            return try context.fetch(request).map { $0.toModel() }
        } catch {
            AppLogger.error(error)
            throw .fetchRecentFailed
        }
    }

    public func moveToTrash(id: UUID, trashFolderID: UUID) throws(VoiceNoteRepositoryError) {
        do {
            guard let entity = try fetchEntity(id: id) else {
                throw VoiceNoteRepositoryError.fetchFailed(id: id)
            }
            guard let trashFolder = try fetchFolderEntity(id: trashFolderID) else {
                throw VoiceNoteRepositoryError.defaultFolderNotFound
            }

            entity.originalFolderID = entity.folder.id
            entity.folder = trashFolder
            entity.deletedAt = .now
            try context.save()
        } catch {
            AppLogger.error(error)
            throw .updateFailed
        }
    }

    public func restore(id: UUID, fallbackFolderID: UUID) throws(VoiceNoteRepositoryError) {
        do {
            guard let entity = try fetchEntity(id: id) else {
                throw VoiceNoteRepositoryError.fetchFailed(id: id)
            }
            let target: FolderEntity = try {
                if let originalID = entity.originalFolderID,
                   let original = try fetchFolderEntity(id: originalID),
                   original.deletedAt == nil
                {
                    return original
                }
                guard let fallback = try fetchFolderEntity(id: fallbackFolderID) else {
                    throw VoiceNoteRepositoryError.defaultFolderNotFound
                }
                return fallback
            }()

            entity.folder = target
            entity.deletedAt = nil
            entity.originalFolderID = nil
            try context.save()
        } catch {
            AppLogger.error(error)
            throw .updateFailed
        }
    }

    public func delete(id: UUID) throws(VoiceNoteRepositoryError) {
        do {
            guard let entity = try fetchEntity(id: id) else {
                throw VoiceNoteRepositoryError.fetchFailed(id: id)
            }
            context.delete(entity)
            try context.save()
        } catch {
            AppLogger.error(error)
            throw .updateFailed
        }
    }

    private func fetchEntity(id: UUID) throws -> VoiceNoteEntity? {
        let request = VoiceNoteEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func fetchFolderEntity(id: UUID) throws -> FolderEntity? {
        let request = FolderEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    /// VoiceNoteEntity NSFetchRequest를 NSFetchedResultsController로 감싸서
    /// AsyncStream<[VoiceNote]>로 변환합니다.
    private func makeListStream(
        request: NSFetchRequest<VoiceNoteEntity>,
        errorOnFailure: () -> VoiceNoteRepositoryError
    ) throws(VoiceNoteRepositoryError) -> AsyncStream<[VoiceNote]> {
        let frc = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        do {
            try frc.performFetch()
        } catch {
            AppLogger.error(error)
            throw errorOnFailure()
        }

        nonisolated(unsafe) let sendableFRC = frc

        return AsyncStream { continuation in
            let initial = (frc.fetchedObjects ?? []).map { $0.toModel() }
            continuation.yield(initial)

            let delegate = FRCStreamDelegate {
                let models = (frc.fetchedObjects ?? []).map { $0.toModel() }
                continuation.yield(models)
            }
            frc.delegate = delegate

            continuation.onTermination = { _ in
                sendableFRC.delegate = nil
                _ = delegate
            }
        }
    }
}
