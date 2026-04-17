@testable import Data
import CoreData
import Domain
import XCTest

@MainActor
final class DefaultFolderRepositoryTest: XCTestCase {
    // MARK: - Helpers

    private func makeSUT() throws -> DefaultFolderRepository {
        let store = try CoreDataLocalDataBase(inMemory: true)
        return DefaultFolderRepository(store: store)
    }
}

// MARK: - 폴더 생성 에러 케이스

extension DefaultFolderRepositoryTest {
    func test_정상적인이름일때_폴더생성시_성공한폴더를반환한다() throws {
        let sut = try makeSUT()
        let name = "새 폴더"

        // When
        let result = try sut.create(Folder(name: name))

        // Then
        XCTAssertEqual(result.name, name)
    }
}

// MARK: - 폴더 조회 성공 및 실패 케이스

extension DefaultFolderRepositoryTest {
    func test_폴더목록이존재할때_전체조회시_폴더리스트를반환한다() throws {
        let sut = try makeSUT()

        // Given
        _ = try sut.create(Folder(name: "폴더1"))
        _ = try sut.create(Folder(name: "폴더2"))

        // When
        let result = try sut.fetchAll()

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains(where: { $0.name == "폴더1" }))
        XCTAssertTrue(result.contains(where: { $0.name == "폴더2" }))
    }

    func test_폴더가없을때_전체조회시_빈배열을반환한다() throws {
        let sut = try makeSUT()

        // When
        let result = try sut.fetchAll()

        // Then
        XCTAssertTrue(result.isEmpty)
    }
}

// MARK: - 폴더 수정 성공 및 실패 케이스

extension DefaultFolderRepositoryTest {
    func test_폴더정보가수정되었을때_업데이트요청시_수정된폴더를반환한다() throws {
        let sut = try makeSUT()

        // Given
        let created = try sut.create(Folder(name: "원래 이름"))
        let updated = Folder(
            id: created.id,
            name: "수정된 이름",
            createdAt: created.createdAt,
            isDeletable: created.isDeletable,
            deletedAt: created.deletedAt
        )

        // When
        let result = try sut.update(updated)

        // Then
        XCTAssertEqual(result.name, "수정된 이름")
    }

    func test_존재하지않는폴더를_업데이트요청시_updateFailed를던진다() throws {
        let sut = try makeSUT()
        let nonExistent = Folder(name: "존재하지 않는 폴더")

        // When & Then
        do {
            _ = try sut.update(nonExistent)
            XCTFail("FolderRepositoryError.updateFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .updateFailed = error else {
                XCTFail("예상한 에러는 FolderRepositoryError.updateFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
                return
            }
        }
    }
}
