import Core
import CoreData

/// Data 레이어의 번들에서 모델을 찾기 위해 클로저 내에서만 사용하는 클래스입니다.
private final class BundleInfo: Sendable {
    static let modelName: String = "ChaGok"
}

/// Core Data 기반의 범용 로컬 데이터베이스입니다.
/// 단일 NSPersistentContainer를 관리하며, 메서드 레벨 제네릭을 통해 모든 엔티티 타입을 처리합니다.
@MainActor
public final class CoreDataLocalDataBase {
    /// NSManagedObjectModel은 인스턴스마다 새로 생성하면 동일 Entity 클래스를 중복 소유해
    /// CoreData 경고가 발생하므로 프로세스 전체에서 단 한 번만 로드합니다.
    @MainActor
    private static let sharedModel: NSManagedObjectModel? = {
        let bundle = Bundle(for: BundleInfo.self)
        return NSManagedObjectModel.mergedModel(from: [bundle])
    }()

    private let container: NSPersistentContainer

    /// Core Data 스토리지를 초기화하고 모델 파일을 로드합니다.
    /// - Parameter inMemory: 메모리 상에서만 동작할지 여부 (테스트 용도)
    public init(inMemory: Bool = false) throws(CoreDataStorageError) {
        guard let model = CoreDataLocalDataBase.sharedModel else {
            throw .resourceNotFound
        }

        let newContainer = NSPersistentContainer(
            name: BundleInfo.modelName,
            managedObjectModel: model
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
    }
}

// MARK: - CRUD

public extension CoreDataLocalDataBase {
    func create<MO: ManagedObjectMapping>(
        _ item: MO.ModelType,
        as entity: MO.Type
    ) throws(CoreDataStorageError) -> MO.ModelType {
        let context = container.viewContext
        do {
            let managedObject = try MO(model: item, context: context)
            try context.save()
            return managedObject.toModel()
        } catch {
            AppLogger.error(error)
            throw .createFailed
        }
    }

    func fetch<MO: ManagedObjectMapping>(
        byID id: MO.ModelType.ID,
        as entity: MO.Type
    ) throws(CoreDataStorageError) -> MO.ModelType {
        let context = container.viewContext
        do {
            guard let entity = try MO.find(byID: id, in: context) else {
                throw CoreDataStorageError.fetchFailed
            }
            return entity.toModel()
        } catch {
            AppLogger.error(error)
            throw .fetchFailed
        }
    }

    func fetchAll<MO: ManagedObjectMapping>(_ entity: MO.Type) throws(CoreDataStorageError) -> [MO.ModelType] {
        let context = container.viewContext
        do {
            let request = NSFetchRequest<MO>(entityName: MO.entityName.rawValue)
            request.sortDescriptors = MO.sortDescriptors
            let entities = try context.fetch(request)
            return entities.map { $0.toModel() }
        } catch {
            AppLogger.error(error)
            throw .fetchAllFailed
        }
    }

    func update<MO: ManagedObjectMapping>(
        _ item: MO.ModelType,
        as entity: MO.Type
    ) throws(CoreDataStorageError) -> MO.ModelType {
        let context = container.viewContext
        do {
            guard let managedObject = try MO.find(for: item, in: context) else {
                throw CoreDataStorageError.updateFailed
            }
            try managedObject.update(from: item)
            try context.save()
            return managedObject.toModel()
        } catch {
            AppLogger.error(error)
            throw .updateFailed
        }
    }

    func delete<MO: ManagedObjectMapping>(
        byID id: MO.ModelType.ID,
        as entity: MO.Type
    ) throws(CoreDataStorageError) -> MO.ModelType {
        let context = container.viewContext
        do {
            guard let managedObject = try MO.find(byID: id, in: context) else {
                throw CoreDataStorageError.deleteFailed
            }
            let domainModel = managedObject.toModel()
            context.delete(managedObject)
            try context.save()
            return domainModel
        } catch {
            AppLogger.error(error)
            throw .deleteFailed
        }
    }

    func observeAll<MO: ManagedObjectMapping>(
        _ entity: MO.Type
    ) throws(CoreDataStorageError) -> AsyncStream<[MO.ModelType]> {
        let context = container.viewContext
        let request = NSFetchRequest<MO>(entityName: MO.entityName.rawValue)
        request.sortDescriptors = MO.sortDescriptors

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
            throw .fetchAllFailed
        }

        nonisolated(unsafe) let sendableFRC = frc

        return AsyncStream { continuation in
            let initial = frc.fetchedObjects?.map { $0.toModel() } ?? []
            continuation.yield(initial)

            let delegate = FRCStreamDelegate {
                let models = frc.fetchedObjects?.map { $0.toModel() } ?? []
                continuation.yield(models)
            }
            frc.delegate = delegate

            continuation.onTermination = { _ in
                sendableFRC.delegate = nil
                _ = delegate
            }
        }
    }

    func observe<MO: ManagedObjectMapping>(
        byID id: MO.ModelType.ID,
        as entity: MO.Type
    ) throws(CoreDataStorageError) -> AsyncStream<MO.ModelType> {
        let context = container.viewContext
        let request = NSFetchRequest<MO>(entityName: MO.entityName.rawValue)
        request.predicate = MO.identityPredicate(byID: id)
        request.sortDescriptors = MO.sortDescriptors
        request.fetchLimit = 1

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

        guard let initialEntity = frc.fetchedObjects?.first else {
            throw .fetchFailed
        }

        nonisolated(unsafe) let sendableFRC = frc

        return AsyncStream { continuation in
            continuation.yield(initialEntity.toModel())

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
    }
}

// MARK: - FRCStreamDelegate

/// NSFetchedResultsControllerDelegate를 클로저 기반으로 브릿지합니다.
@MainActor
private final class FRCStreamDelegate: NSObject, NSFetchedResultsControllerDelegate {
    private let onChange: @MainActor () -> Void

    init(onChange: @escaping @MainActor () -> Void) {
        self.onChange = onChange
    }

    nonisolated func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        MainActor.assumeIsolated {
            onChange()
        }
    }
}
