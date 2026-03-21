@testable import Data
import CoreData
import XCTest

final class CoreDataStorageTests: XCTestCase {
    func test_CoreDataLocalDataBase_인메모리모드로_정상적으로_초기화되어야한다() async throws {
        // Given
        let database = try await CoreDataLocalDataBase<FolderEntity>(inMemory: true)

        // Then
        let container = await database.container
        XCTAssertEqual(container.name, "ChaGok")
        XCTAssertEqual(container.persistentStoreDescriptions.first?.type, NSInMemoryStoreType)
        XCTAssertTrue(container.viewContext.automaticallyMergesChangesFromParent)
    }
}
