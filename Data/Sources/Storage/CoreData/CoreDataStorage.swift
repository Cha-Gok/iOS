import CoreData
import Domain
import Foundation

/// Data 레이어의 번들에서 모델을 찾기 위해 클로저 내에서만 사용하는 클래스입니다.
final class BundleInfo: Sendable {
    static let EntityName: String = "ChaGok"
    static let ExtensionName: String = "momd"
}

public actor CoreDataStorage: Sendable {
    public let container: NSPersistentContainer

    /// 싱글톤을 제거하고 외부에서 직접 생성할 수 있도록 public init으로 변경합니다.
    public init(inMemory: Bool = false) throws(CoreDataStorageError) {
        let bundle = Bundle(for: BundleInfo.self)
        guard let modelURL = bundle.url(forResource: BundleInfo.EntityName, withExtension: BundleInfo.ExtensionName),
              let model = NSManagedObjectModel(contentsOf: modelURL)
        else {
            throw .resourceNotFound
        }

        container = NSPersistentContainer(name: BundleInfo.EntityName, managedObjectModel: model)

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

    /// 컨텍스트의 변경 사항을 저장합니다.
    public func saveContext(backgroundContext: NSManagedObjectContext? = nil) async throws(CoreDataStorageError) {
        let context = backgroundContext ?? container.viewContext

        let result: Result<Void, CoreDataStorageError>
        result = await context.perform {
            guard context.hasChanges else { return .success(()) }
            do {
                try context.save()
                return .success(())
            } catch {
                return .failure(.unknown(error))
            }
        }
        try result.get()
    }
}
