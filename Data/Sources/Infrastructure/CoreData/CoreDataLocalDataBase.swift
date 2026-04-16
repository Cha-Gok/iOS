import Core
import CoreData

/// Data 레이어의 번들에서 모델을 찾기 위해 클로저 내에서만 사용하는 클래스입니다.
private final class BundleInfo: Sendable {
    static let modelName: String = "ChaGok"
}

/// Core Data 기반의 범용 로컬 데이터베이스입니다.
/// 단일 NSPersistentContainer를 관리하며, 메서드 레벨 제네릭을 통해 모든 엔티티 타입을 처리합니다.
public final class CoreDataLocalDataBase: Sendable {
    /// NSManagedObjectModel은 인스턴스마다 새로 생성하면 동일 Entity 클래스를 중복 소유해
    /// CoreData 경고가 발생하므로 프로세스 전체에서 단 한 번만 로드합니다.
    private nonisolated(unsafe) static let sharedModel: NSManagedObjectModel = {
        let bundle = Bundle(for: BundleInfo.self)
        guard let model = NSManagedObjectModel.mergedModel(from: [bundle]) else {
            fatalError("CoreDataLocalDataBase: NSManagedObjectModel 로드 실패 — 번들에 .momd 파일이 있는지 확인하세요.")
        }
        return model
    }()

    private let container: NSPersistentContainer
    private let backgroundContext: NSManagedObjectContext

    /// Core Data 스토리지를 초기화하고 모델 파일을 로드합니다.
    /// - Parameter inMemory: 메모리 상에서만 동작할지 여부 (테스트 용도)
    public init(inMemory: Bool = false) throws(CoreDataStorageError) {
        let newContainer = NSPersistentContainer(
            name: BundleInfo.modelName,
            managedObjectModel: CoreDataLocalDataBase.sharedModel
        )

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            newContainer.persistentStoreDescriptions = [description]
        }

        var initializationError: Error?
        newContainer.loadPersistentStores { _, error in
            initializationError = error
        }

        if let initializationError {
            AppLogger.error(initializationError)
            throw .initializeFailed
        }

        container = newContainer
        backgroundContext = newContainer.newBackgroundContext()
    }
}

// MARK: - CRUD

public extension CoreDataLocalDataBase {
    func create<MO: ManagedObjectMapping>(
        _ item: MO.ModelType,
        as entity: MO.Type
    ) async throws(CoreDataStorageError) -> MO.ModelType {
        do {
            return try await backgroundContext.perform { [backgroundContext] in
                let managedObject = try MO(model: item, context: backgroundContext)
                try backgroundContext.save()
                return managedObject.toModel()
            }
        } catch {
            AppLogger.error(error)
            throw .createFailed
        }
    }

    func fetch<MO: ManagedObjectMapping>(
        byID id: MO.ModelType.ID,
        as entity: MO.Type
    ) async throws(CoreDataStorageError) -> MO.ModelType {
        do {
            return try await backgroundContext.perform { [backgroundContext] in
                guard let entity = try MO.find(byID: id, in: backgroundContext) else {
                    throw CoreDataStorageError.fetchFailed
                }
                return entity.toModel()
            }
        } catch {
            AppLogger.error(error)
            throw .fetchFailed
        }
    }

    func fetchAll<MO: ManagedObjectMapping>(_ entity: MO.Type) async throws(CoreDataStorageError) -> [MO.ModelType] {
        do {
            return try await backgroundContext.perform { [backgroundContext] in
                let request = NSFetchRequest<MO>(entityName: MO.entityName.rawValue)
                request.sortDescriptors = MO.sortDescriptors
                let entities = try backgroundContext.fetch(request)
                return entities.map { $0.toModel() }
            }
        } catch {
            AppLogger.error(error)
            throw .fetchAllFailed
        }
    }

    func update<MO: ManagedObjectMapping>(
        _ item: MO.ModelType,
        as entity: MO.Type
    ) async throws(CoreDataStorageError) -> MO.ModelType {
        do {
            return try await backgroundContext.perform { [backgroundContext] in
                guard let managedObject = try MO.find(for: item, in: backgroundContext) else {
                    throw CoreDataStorageError.updateFailed
                }
                try managedObject.update(from: item)
                try backgroundContext.save()
                return managedObject.toModel()
            }
        } catch {
            AppLogger.error(error)
            throw .updateFailed
        }
    }

    func delete<MO: ManagedObjectMapping>(
        byID id: MO.ModelType.ID,
        as entity: MO.Type
    ) async throws(CoreDataStorageError) -> MO.ModelType {
        do {
            return try await backgroundContext.perform { [backgroundContext] in
                guard let managedObject = try MO.find(byID: id, in: backgroundContext) else {
                    throw CoreDataStorageError.deleteFailed
                }
                let domainModel = managedObject.toModel()
                backgroundContext.delete(managedObject)
                try backgroundContext.save()
                return domainModel
            }
        } catch {
            AppLogger.error(error)
            throw .deleteFailed
        }
    }
}
