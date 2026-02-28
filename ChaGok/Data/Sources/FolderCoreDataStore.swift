import CoreData
import Domain

struct FolderCoreDataStore {
    private let container: NSPersistentContainer
    
    // 추후 BackgroundContext 사용 시 교체 용이성을 위한 연산 프로퍼티
    private var context: NSManagedObjectContext {
        container.viewContext
    }

    init(container: NSPersistentContainer) {
        self.container = container
    }

    /// Create Folder CoreData 구현체
    func create(_ name: String) async throws -> Folder {

        await context.perform {
            let folder: Folder = .init(context: context)
            let current: Date = .now

            folder.id = UUID()
            folder.createdAt = current
            folder.updatedAt = current
            folder.name = name
            folder.path = URL.applicationSupportDirectory

            return folder
        }
    }

    /// Fetch Folder  CoreData 구현체
    func fetchAll() async throws -> [Folder] {

        try await context.perform {
            let request: NSFetchRequest<Folder> = Folder.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Folder.createdAt, ascending: false)
            ]

            return try context.fetch(request)
        }
    }

    /// 특정 Entity - id를 통해 조회 하기
    func fetch(byId id: UUID) throws -> Folder? {

        let request: NSFetchRequest<Folder> = Folder.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    /// Entity 속성 수정 기능
    func update(with folder: Domain.Folder) async throws -> Folder {

        try await context.perform {
            guard let entity = try self.fetch(byId: folder.id) else {
                throw FolderError.notFound
            }
            entity.name = folder.name
            entity.path = folder.path
            entity.updatedAt = .now

            return entity
        }
    }

    // Entity 삭제 기능
    func delete(byId id: UUID) async throws {
        try await context.perform {
            guard let entity = try self.fetch(byId: id) else {
                throw FolderError.notFound
            }
            context.delete(entity)
        }
    }
}

// MARK: - Folder Entity Optional 변환 처리
extension FolderCoreDataStore {
    func fromOptional(_ folder: Folder) -> Domain.Folder {
        Domain.Folder(
            id: folder.id ?? UUID(),
            path: folder.path ?? URL.applicationSupportDirectory,
            name: folder.name ?? "None Type Folder",
            createdAt: folder.createdAt ?? .now
        )
    }
}
