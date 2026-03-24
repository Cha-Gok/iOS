@testable import Data
import CoreData
import Domain
import XCTest

/// Core Data 스토리지의 공통 초기화 및 EntityName 검증 테스트입니다.
/// Entity별 CRUD 테스트는 FolderEntityTests, VoiceNoteEntityTests에서 수행합니다.
final class CoreDataStorageTests: XCTestCase {
    // MARK: - Init

    func test_인메모리모드일때_스토리지초기화시_정상적으로세팅된다() async throws {
        // Given
        let database = try await CoreDataLocalDataBase<FolderEntity>(inMemory: true)

        // Then
        let container = await database.container
        XCTAssertEqual(container.name, "ChaGok")
        XCTAssertEqual(container.persistentStoreDescriptions.first?.type, NSInMemoryStoreType)
        XCTAssertTrue(container.viewContext.automaticallyMergesChangesFromParent)
    }

    // MARK: - EntityName

    func test_FolderEntity의entityName은_folder이다() {
        XCTAssertEqual(FolderEntity.entityName, .folder)
    }

    func test_VoiceNoteEntity의entityName은_voiceNote이다() {
        XCTAssertEqual(VoiceNoteEntity.entityName, .voiceNote)
    }

    func test_CoreDataEntityName의_전체케이스수는_6개이다() {
        XCTAssertEqual(CoreDataEntityName.allCases.count, 6)
    }
}
