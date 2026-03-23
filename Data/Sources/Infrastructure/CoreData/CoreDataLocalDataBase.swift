import Core
import CoreData
import Domain

/// Data 레이어의 번들에서 모델을 찾기 위해 클로저 내에서만 사용하는 클래스입니다.
private final class BundleInfo: Sendable {
    static let EntityName: String = "ChaGok"
    static let ExtensionName: String = "momd"
}

/// Core Data를 사용하는 범용 로컬 데이터베이스 구현체입니다.
/// MO(ManagedObjectMapping) 타입을 통해 엔티티와 도메인 모델 간의 매핑 정보를 주입받아 동작합니다.
/// actor로 선언되어 스레드 안전성을 보장하며, 내부적으로 backgroundContext를 사용하여 작업을 처리합니다.
public actor CoreDataLocalDataBase<MO: ManagedObjectMapping>: LocalDataBase {
    /// 해당 스토리지에서 다루는 도메인 모델 타입
    public typealias Domain = MO.DomainType

    let container: NSPersistentContainer
    let backgroundContext: NSManagedObjectContext

    /// Core Data 스토리지를 초기화하고 모델 파일을 로드합니다.
    /// - Parameter inMemory: 메모리 상에서만 동작할지 여부 (테스트 용도)
    public init(inMemory: Bool = false) async throws(CoreDataStorageError) {
        let bundle = Bundle(for: BundleInfo.self)

        // 모델 파일(.momd) 경로 확인 및 로드
        guard
            let modelURL = bundle.url(
                forResource: BundleInfo.EntityName, withExtension: BundleInfo.ExtensionName
            ),
            let model = NSManagedObjectModel(contentsOf: modelURL)
        else {
            throw .resourceNotFound
        }

        let newContainer = NSPersistentContainer(name: BundleInfo.EntityName, managedObjectModel: model)

        if inMemory {
            // 메모리 스토어 설정 (데이터가 영구 저장되지 않음)
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            newContainer.persistentStoreDescriptions = [description]
        }

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                newContainer.loadPersistentStores { _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } catch {
            throw .initializeFailed
        }

        newContainer.viewContext.automaticallyMergesChangesFromParent = true

        // 1. 컨테이너 등록
        container = newContainer
        // 2. 스토어 로드 완료 후 백그라운드 컨텍스트 생성
        backgroundContext = newContainer.newBackgroundContext()
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

    func fetch(byId id: Domain.ID) async throws -> Domain {
        let backgroundContext = backgroundContext
        return try await backgroundContext.perform {
            do {
                guard let entity = try MO.find(byId: id, in: backgroundContext) else {
                    throw CoreDataStorageError.fetchFailed
                }
                return entity.toDomain()
            } catch {
                AppLogger.error(error)
                throw CoreDataStorageError.fetchFailed
            }
        }
    }

    func fetchAll() async throws -> [Domain] {
        let backgroundContext = backgroundContext

        return try await backgroundContext.perform {
            do {
                let request = NSFetchRequest<MO>(entityName: MO.entityName.rawValue)
                request.sortDescriptors = MO.sortDescriptors

                let entities = try backgroundContext.fetch(request)
                return entities.map { $0.toDomain() }
            } catch {
                AppLogger.error(error)
                throw CoreDataStorageError.fetchAllFailed
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
                AppLogger.error(error)
                throw CoreDataStorageError.updateFailed
            }
        }
    }

    func delete(byId id: Domain.ID) async throws -> Domain {
        let backgroundContext = backgroundContext

        return try await backgroundContext.perform {
            do {
                guard let managedObject = try MO.find(byId: id, in: backgroundContext) else {
                    throw CoreDataStorageError.deleteFailed
                }

                let domainModel = managedObject.toDomain()
                backgroundContext.delete(managedObject)
                try backgroundContext.save()
                return domainModel
            } catch {
                AppLogger.error(error)
                throw CoreDataStorageError.deleteFailed
            }
        }
    }
}
