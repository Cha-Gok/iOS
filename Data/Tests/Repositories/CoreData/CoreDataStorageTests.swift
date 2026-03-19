@testable import Data
import CoreData
import XCTest

final class CoreDataStorageTests: XCTestCase {
    func test_CoreDataStorage_인메모리모드로_정상적으로_초기화되어야한다() async throws {
        // Given
        let storage = try CoreDataStorage(inMemory: true)

        // When
        try await storage.setup()

        // Then
        let container = await storage.container
        XCTAssertEqual(container.name, "ChaGok")
        XCTAssertEqual(container.persistentStoreDescriptions.first?.type, NSInMemoryStoreType)
        XCTAssertTrue(container.viewContext.automaticallyMergesChangesFromParent)
    }

    func test_CoreDataStorage_setup호출후_데이터저장이_가능해야한다() async throws {
        // Given
        let storage = try CoreDataStorage(inMemory: true)
        try await storage.setup()
        let container = await storage.container
        let context = container.viewContext

        // When - 간단한 엔티티(Folder) 생성 테스트
        let folder = FolderEntity(context: context)
        folder.id = UUID()
        folder.name = "Test Folder"
        folder.createdAt = Date()
        folder.path = URL.applicationSupportDirectory

        // Then
        XCTAssertTrue(context.hasChanges)
        try await storage.saveContext()
        XCTAssertFalse(context.hasChanges)
    }
}
