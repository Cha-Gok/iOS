@testable import Data
import CoreData
import Domain
import XCTest

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

    // MARK: - Create

    func test_새로운엔티티가주어졌을때_저장요청시_저장된데이터를반환한다() async throws {
        // Given
        let database = try await CoreDataLocalDataBase<FolderEntity>(inMemory: true)
        let folder = Folder(name: "New Folder")

        // When
        let savedFolder = try await database.create(folder)

        // Then
        XCTAssertEqual(savedFolder.id, folder.id)
        XCTAssertEqual(savedFolder.name, "New Folder")
    }

    // MARK: - Read

    func test_엔티티가존재할때_ID로조회시_해당데이터를반환한다() async throws {
        // Given
        let database = try await CoreDataLocalDataBase<FolderEntity>(inMemory: true)
        let folder = Folder(name: "Existing Folder")
        _ = try await database.create(folder)

        // When
        let fetchedFolder = try await database.fetch(byId: folder.id)

        // Then
        XCTAssertEqual(fetchedFolder.id, folder.id)
        XCTAssertEqual(fetchedFolder.name, "Existing Folder")
    }

    func test_엔티티가존재하지않을때_ID로조회시_fetchFailed에러를던진다() async throws {
        // Given
        let database = try await CoreDataLocalDataBase<FolderEntity>(inMemory: true)
        let unknownId = UUID()

        // When & Then
        do {
            _ = try await database.fetch(byId: unknownId)
            XCTFail("에러가 발생해야 합니다.")
        } catch let error as CoreDataStorageError {
            guard case .fetchFailed = error else {
                return XCTFail("예상한 에러는 .fetchFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        } catch {
            XCTFail("예상치 못한 에러: \(error)")
        }
    }

    func test_엔티티목록이존재할때_전체조회시_모든데이터를반환한다() async throws {
        // Given
        let database = try await CoreDataLocalDataBase<FolderEntity>(inMemory: true)
        let folder1 = Folder(name: "Folder 1")
        let folder2 = Folder(name: "Folder 2")
        _ = try await database.create(folder1)
        _ = try await database.create(folder2)

        // When
        let allFolders = try await database.fetchAll()

        // Then
        XCTAssertEqual(allFolders.count, 2)
        XCTAssertTrue(allFolders.contains(where: { $0.id == folder1.id }))
        XCTAssertTrue(allFolders.contains(where: { $0.id == folder2.id }))
    }

    // MARK: - Update

    func test_기존엔티티가존재할때_수정요청시_수정된데이터를반환한다() async throws {
        // Given
        let database = try await CoreDataLocalDataBase<FolderEntity>(inMemory: true)
        let folder = Folder(name: "Original Folder")
        _ = try await database.create(folder)

        // When
        let updatedFolder = Folder(
            id: folder.id,
            name: "Updated Folder",
            createdAt: folder.createdAt,
            content: folder.content,
            isDeletable: folder.isDeletable,
            deletedAt: folder.deletedAt
        )
        let result = try await database.update(updatedFolder)

        // Then
        XCTAssertEqual(result.id, folder.id)
        XCTAssertEqual(result.name, "Updated Folder")
    }

    func test_엔티티가존재하지않을때_수정요청시_updateFailed에러를던진다() async throws {
        // Given
        let database = try await CoreDataLocalDataBase<FolderEntity>(inMemory: true)
        let unknownFolder = Folder(name: "Unknown Folder")

        // When & Then
        do {
            _ = try await database.update(unknownFolder)
            XCTFail("에러가 발생해야 합니다.")
        } catch let error as CoreDataStorageError {
            guard case .updateFailed = error else {
                return XCTFail("예상한 에러는 .updateFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        } catch {
            XCTFail("예상치 못한 에러: \(error)")
        }
    }

    // MARK: - Delete

    func test_기존엔티티가존재할때_삭제요청시_삭제된데이터를반환하고_다시조회할수없다() async throws {
        // Given
        let database = try await CoreDataLocalDataBase<FolderEntity>(inMemory: true)
        let folder = Folder(name: "Folder to Delete")
        _ = try await database.create(folder)

        // When
        let deletedFolder = try await database.delete(byId: folder.id)

        // Then
        XCTAssertEqual(deletedFolder.id, folder.id)

        do {
            _ = try await database.fetch(byId: folder.id)
            XCTFail("데이터가 지워졌으므로 에러가 발생해야 합니다.")
        } catch let error as CoreDataStorageError {
            guard case .fetchFailed = error else {
                return XCTFail("예상한 에러는 .fetchFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        } catch {
            XCTFail("예상치 못한 에러: \(error)")
        }
    }

    func test_엔티티가존재하지않을때_삭제요청시_deleteFailed에러를던진다() async throws {
        // Given
        let database = try await CoreDataLocalDataBase<FolderEntity>(inMemory: true)
        let unknownId = UUID()

        // When & Then
        do {
            _ = try await database.delete(byId: unknownId)
            XCTFail("에러가 발생해야 합니다.")
        } catch let error as CoreDataStorageError {
            guard case .deleteFailed = error else {
                return XCTFail("예상한 에러는 .deleteFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        } catch {
            XCTFail("예상치 못한 에러: \(error)")
        }
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
