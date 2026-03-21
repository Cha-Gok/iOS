import CoreData
import Domain
import Foundation

/// Data 레이어의 번들에서 모델을 찾기 위해 클로저 내에서만 사용하는 클래스입니다.
fileprivate final class BundleInfo: Sendable {
    static let EntityName: String = "ChaGok"
    static let ExtensionName: String = "momd"
}

/// Core Data를 사용하는 범용 로컬 데이터 소스의 실구현체입니다.
/// 내부적으로 `backgroundContext.perform`을 호출하여 비동기 작업 및 트랜잭션을 직접 관리합니다.
public actor CoreDataLocalDataBase<MO: ManagedObjectMapping>: LocalDataBase {
    public typealias Domain = MO.DomainType

    let container: NSPersistentContainer
    let backgroundContext: NSManagedObjectContext

    /// Core Data 스토리지를 초기화합니다.
    public init(inMemory: Bool = false) async throws(CoreDataStorageError) {
        let bundle = Bundle(for: BundleInfo.self)
        guard let modelURL = bundle.url(forResource: BundleInfo.EntityName, withExtension: BundleInfo.ExtensionName),
              let model = NSManagedObjectModel(contentsOf: modelURL)
        else {
            throw .resourceNotFound
        }

        container = NSPersistentContainer(name: BundleInfo.EntityName, managedObjectModel: model)
        backgroundContext = container.newBackgroundContext()
        try await setup()

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }
    }

    /// container 초기 설정을 실행합니다.
    public func setup() async throws(CoreDataStorageError) {
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                container.loadPersistentStores { _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        self.container.viewContext.automaticallyMergesChangesFromParent = true
                        continuation.resume()
                    }
                }
            }
        } catch {
            throw .initializeFailed
        }
    }
}

// MARK: - CoreData ( C, R, U )

public extension CoreDataLocalDataBase {
    func create(_ item: Domain) async throws -> Domain {
        let backgroundContext = backgroundContext

        return try await backgroundContext.perform {
            do {
                let managedObject = MO(domain: item, context: backgroundContext)
                try backgroundContext.save()
                return managedObject.toDomain()
            } catch {
                throw CoreDataStorageError.createFailed
            }
        }
    }

    func fetch() async throws -> [Domain] {
        let backgroundContext = backgroundContext

        return try await backgroundContext.perform {
            do {
                let request = NSFetchRequest<MO>(entityName: MO.entityName)
                request.sortDescriptors = MO.sortDescriptors

                let entities = try backgroundContext.fetch(request)
                return entities.map { $0.toDomain() }
            } catch {
                throw CoreDataStorageError.fetchFailed
            }
        }
    }

    func update(_ item: Domain) async throws -> Domain {
        let backgroundContext = backgroundContext

        return try await backgroundContext.perform {
            do {
                guard let managedObject = try MO.find(for: item, in: backgroundContext) else {
                    throw CoreDataStorageError.updateFailed
                }

                managedObject.insert(from: item)

                try backgroundContext.save()
                return managedObject.toDomain()
            } catch {
                throw CoreDataStorageError.updateFailed
            }
        }
    }

    func delete(_ item: Domain) async throws -> Domain {
        let backgroundContext = backgroundContext

        return try await backgroundContext.perform {
            do {
                guard let managedObject = try MO.find(for: item, in: backgroundContext) else {
                    throw CoreDataStorageError.deleteFailed
                }

                let domainModel = managedObject.toDomain()
                backgroundContext.delete(managedObject)
                try backgroundContext.save()
                return domainModel
            } catch {
                throw CoreDataStorageError.deleteFailed
            }
        }
    }
}
