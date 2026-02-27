import Foundation
import CoreData
import Domain

/// Data 레이어의 번들에서 모델을 찾습니다.
private final class BundleInfo {
    /// Core Data Entity 이름
    static let EntityName: String = "ChaGok"
    /// 확장자 이름
    static let ExtensionName: String = "momd"
}

public final class PersistenceController {
    nonisolated(unsafe) private static var shared: PersistenceController?
    nonisolated(unsafe) private static var preview: PersistenceController?
    public let container: NSPersistentContainer

    private init(inMemory: Bool = false) throws {

        let bundle = Bundle(for: BundleInfo.self)
        guard let modelURL = bundle.url(forResource: BundleInfo.EntityName, withExtension: BundleInfo.ExtensionName),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw Domain.ChaGokSystemError.initializeCoreDataFailed
        }

        container = NSPersistentContainer(name: BundleInfo.EntityName, managedObjectModel: model)

        if inMemory {
            if let storeDescription = container.persistentStoreDescriptions.first {
                storeDescription.url = URL(fileURLWithPath: "/dev/null")
            }
        }

        var loadError: Error?
        container.loadPersistentStores { (_, error) in
            loadError = error
        }

        if let _ = loadError {
            throw Domain.ChaGokSystemError.initializeCoreDataFailed
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    public func saveContext(backgroundContext: NSManagedObjectContext? = nil) throws {
        let context = backgroundContext ?? container.viewContext

        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch let error as NSError {
            // 용량 부족 에러 처리
            if error.domain == NSCocoaErrorDomain && error.code == NSFileWriteOutOfSpaceError {
                throw Domain.ChaGokSystemError.systemStorageIsFull
            }

            // 일반적인 영속성 커밋 실패
            throw Domain.FolderError.unknown(error)
        }
    }
}

// MARK: - static 인스턴스 접근을 위한 Lock
private let lock = NSLock()

// MARK: - throws 에러 처리
extension PersistenceController {
    public enum Method {
        case shared
        case preview
    }

    public static func getInstance(method: Method = .shared) throws -> PersistenceController {
        lock.lock()
        defer { lock.unlock() }

        switch method {
        case .shared:
            if let shared = shared { return shared }
            let shared = try PersistenceController(inMemory: false)
            return shared
        case .preview:
            if let preview = preview { return preview }
            let preview = try PersistenceController(inMemory: true)
            return preview
        }
    }
}
