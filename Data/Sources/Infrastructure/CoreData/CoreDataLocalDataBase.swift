import Core
import CoreData

/// Data 레이어의 번들에서 모델을 찾기 위해 클로저 내에서만 사용하는 클래스입니다.
private final class BundleInfo: Sendable {
    static let modelName: String = "ChaGok"
}

/// Core Data NSPersistentContainer 셋업 wrapper.
/// CRUD/observe 같은 데이터 접근 로직은 각 Repository에서 직접 처리합니다.
@MainActor
public final class CoreDataLocalDataBase {
    /// NSManagedObjectModel은 인스턴스마다 새로 생성하면 동일 Entity 클래스를 중복 소유해
    /// CoreData 경고가 발생하므로 프로세스 전체에서 단 한 번만 로드합니다.
    @MainActor
    private static let sharedModel: NSManagedObjectModel? = {
        let bundle = Bundle(for: BundleInfo.self)
        return NSManagedObjectModel.mergedModel(from: [bundle])
    }()

    public let container: NSPersistentContainer

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
