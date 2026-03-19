import Core
import CoreData
import Domain

/// Core Data를 사용하는 폴더 로컬 데이터 소스의 실구현체입니다.
/// 내부적으로 `backgroundContext.perform`을 호출하여 비동기 작업 및 트랜잭션을 직접 관리합니다.
public struct CoreDataFolderLocalDataSource: FolderLocalDataSource {
    private let backgroundContext: NSManagedObjectContext

    public init(backgroundContext: NSManagedObjectContext) {
        self.backgroundContext = backgroundContext
    }

    public func create(name: String) async throws -> Folder {
        try await backgroundContext.perform {
            let entity = FolderEntity(context: backgroundContext)
            let current = Date.now

            entity.id = UUID()
            entity.name = name
            entity.createdAt = current
            entity.updatedAt = current
            entity.path = URL.applicationSupportDirectory

            try backgroundContext.save()
            return entity.toDomain()
        }
    }

    public func fetch() async throws -> [Folder] {
        try await backgroundContext.perform {
            let request = FolderEntity.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \FolderEntity.createdAt, ascending: true)
            ]

            guard let entities = try backgroundContext.fetch(request) as? [FolderEntity] else {
                throw FolderRepositoryError.fetchFailed
            }

            return entities.map { $0.toDomain() }
        }
    }

    public func update(_ folder: Folder) async throws -> Folder {
        try await backgroundContext.perform {
            let request = FolderEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", folder.id as CVarArg)
            request.fetchLimit = 1

            guard let entity = try backgroundContext.fetch(request).first as? FolderEntity else {
                throw FolderRepositoryError.notFound
            }

            entity.name = folder.name
            entity.updatedAt = Date.now

            try backgroundContext.save()
            return entity.toDomain()
        }
    }
}
