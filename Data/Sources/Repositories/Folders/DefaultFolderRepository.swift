import Core
import CoreData
import Domain
import Foundation

/// Folders 도메인을 위한 리포지토리 실구현체입니다.
@MainActor
public struct DefaultFolderRepository: FolderRepository {
    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    public func create(_ folder: Folder) throws(FolderRepositoryError) -> Folder {
        do {
            let entity = FolderEntity(model: folder, context: context)
            try context.save()
            return entity.toModel()
        } catch {
            AppLogger.error(error)
            throw .createFailed
        }
    }

    public func fetchAll() throws(FolderRepositoryError) -> [Folder] {
        do {
            let request = FolderEntity.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \FolderEntity.createdAt, ascending: false)
            ]
            return try context.fetch(request).map { $0.toModel() }
        } catch {
            AppLogger.error(error)
            throw .fetchFailed
        }
    }

    public func fetch(by id: UUID) throws(FolderRepositoryError) -> Folder {
        let request = FolderEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        let result: [FolderEntity]
        do {
            result = try context.fetch(request)
        } catch {
            AppLogger.error(error)
            throw .fetchFailed
        }

        guard let entity = result.first else {
            throw .notFound
        }
        return entity.toModel()
    }

    public func fetch(by kind: FolderKind) throws(FolderRepositoryError) -> [Folder] {
        do {
            let request = FolderEntity.fetchRequest()
            request.predicate = NSPredicate(format: "kindRaw == %@", kind.rawValue)
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \FolderEntity.createdAt, ascending: false)
            ]
            return try context.fetch(request).map { $0.toModel() }
        } catch {
            AppLogger.error(error)
            throw .fetchFailed
        }
    }

    public func update(_ folder: Folder) throws(FolderRepositoryError) -> Folder {
        do {
            let request = FolderEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", folder.id as CVarArg)
            request.fetchLimit = 1
            guard let entity = try context.fetch(request).first else {
                throw FolderRepositoryError.notFound
            }
            entity.update(from: folder)
            try context.save()
            return entity.toModel()
        } catch {
            AppLogger.error(error)
            throw .updateFailed
        }
    }

    public func observe(by kind: FolderKind) throws(FolderRepositoryError) -> AsyncStream<[Folder]> {
        let request = FolderEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "kindRaw == %@ AND parentID == nil",
            kind.rawValue
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FolderEntity.createdAt, ascending: false)]
        return try makeListStream(request: request)
    }

    public func observeTrashed() throws(FolderRepositoryError) -> AsyncStream<[Folder]> {
        let request = FolderEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "parentID != nil AND kindRaw == %@",
            FolderKind.custom.rawValue
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FolderEntity.deletedAt, ascending: false)]
        return try makeListStream(request: request)
    }

    public func delete(id: UUID) throws(FolderRepositoryError) {
        do {
            guard let entity = try fetchEntity(id: id) else {
                throw FolderRepositoryError.notFound
            }
            context.delete(entity) // xcdatamodel cascade rule이 안의 노트도 삭제
            try context.save()
        } catch {
            AppLogger.error(error)
            throw .updateFailed
        }
    }

    private func fetchEntity(id: UUID) throws -> FolderEntity? {
        let request = FolderEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func makeListStream(
        request: NSFetchRequest<FolderEntity>
    ) throws(FolderRepositoryError) -> AsyncStream<[Folder]> {
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
            throw .fetchFailed
        }

        nonisolated(unsafe) let sendableFRC = frc

        return AsyncStream { continuation in
            let initial = (sendableFRC.fetchedObjects ?? []).map { $0.toModel() }
            continuation.yield(initial)

            let delegate = FRCStreamDelegate {
                let models = (sendableFRC.fetchedObjects ?? []).map { $0.toModel() }
                continuation.yield(models)
            }
            sendableFRC.delegate = delegate

            continuation.onTermination = { _ in
                sendableFRC.delegate = nil
                _ = delegate
            }
        }
    }
}
