import Core
import CoreData
import Domain
import Foundation

/// Folders 도메인을 위한 리포지토리 실구현체입니다.
public struct DefaultFolderRepository: FolderRepository {
    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    public func create(_ folder: Folder) throws(FolderRepositoryError) -> Folder {
        do {
            return try store.create(folder, as: FolderEntity.self)
        } catch {
            AppLogger.error(error)
            throw .createFailed
        }
    }

    public func fetchAll() throws(FolderRepositoryError) -> [Folder] {
        do {
            return try store.fetchAll(FolderEntity.self)
        } catch {
            AppLogger.error(error)
            throw .fetchFailed
        }
    }

    public func fetch(by id: UUID) throws(FolderRepositoryError) -> Folder {
        do {
            return try store.fetch(byID: id, as: FolderEntity.self)
        } catch {
            AppLogger.error(error)
            throw .fetchFailed
        }
    }

    public func update(_ folder: Folder) throws(FolderRepositoryError) -> Folder {
        do {
            return try store.update(folder, as: FolderEntity.self)
        } catch {
            AppLogger.error(error)
            throw .updateFailed
        }
    }

    public func observeAll() throws(FolderRepositoryError) -> AsyncStream<[Folder]> {
        do {
            return try store.observeAll(FolderEntity.self)
        } catch {
            AppLogger.error(error)
            throw .fetchFailed
        }
    }
}
