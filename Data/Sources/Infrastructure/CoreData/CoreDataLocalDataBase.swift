import Core
import CoreData

/// Core Data NSPersistentContainer 셋업 wrapper.
/// CRUD/observe 같은 데이터 접근 로직은 각 Repository에서 직접 처리합니다.
@MainActor
public final class CoreDataLocalDataBase {
    private static let modelName: String = "ChaGok"

    public let container: NSPersistentContainer

    /// Core Data 스토리지를 초기화하고 모델 파일을 로드합니다.
    /// - Parameter inMemory: 메모리 상에서만 동작할지 여부 (테스트 용도)
    public init(inMemory: Bool = false) throws(CoreDataStorageError) {
        let bundle = Bundle(for: CoreDataLocalDataBase.self)
        guard let model = NSManagedObjectModel.mergedModel(from: [bundle]) else {
            throw .resourceNotFound
        }

        let newContainer = NSPersistentContainer(
            name: CoreDataLocalDataBase.modelName,
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
