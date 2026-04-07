@testable import Data
import CoreData
import Domain
import XCTest

final class DefaultFolderRepositoryTest: XCTestCase {
    // MARK: - Helpers

    private func makeSUT() async throws -> DefaultFolderRepository {
        let store = try await CoreDataStore(inMemory: true)
        return DefaultFolderRepository(store: store)
    }
}

// MARK: - 폴더 생성 에러 및 취소 케이스

extension DefaultFolderRepositoryTest {
    func test_정상적인이름일때_폴더생성시_성공한폴더를반환한다() async throws {
        let sut = try await makeSUT()
        let name = "새 폴더"

        // When
        let result = try await sut.create(name: name)

        // Then
        XCTAssertEqual(result.name, name)
    }

    func test_태스크가취소된상태에서_생성요청시_cancelled를던진다() async throws {
        let sut = try await makeSUT()

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.create(name: "취소될폴더")
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("FolderRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? FolderRepositoryError else {
                return XCTFail("예상한 에러는 FolderRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
    }
}

// MARK: - 폴더 조회 성공 및 실패 케이스

extension DefaultFolderRepositoryTest {
    func test_폴더목록이존재할때_전체조회시_폴더리스트를반환한다() async throws {
        let sut = try await makeSUT()

        // Given
        _ = try await sut.create(name: "폴더1")
        _ = try await sut.create(name: "폴더2")

        // When
        let result = try await sut.fetchAll()

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains(where: { $0.name == "폴더1" }))
        XCTAssertTrue(result.contains(where: { $0.name == "폴더2" }))
    }

    func test_폴더가없을때_전체조회시_빈배열을반환한다() async throws {
        let sut = try await makeSUT()

        // When
        let result = try await sut.fetchAll()

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func test_태스크가취소된상태에서_전체조회요청시_cancelled를던진다() async throws {
        let sut = try await makeSUT()

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.fetchAll()
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("FolderRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? FolderRepositoryError else {
                return XCTFail("예상한 에러는 FolderRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
    }
}

// MARK: - 폴더 수정 성공 및 실패 케이스

extension DefaultFolderRepositoryTest {
    func test_폴더정보가수정되었을때_업데이트요청시_수정된폴더를반환한다() async throws {
        let sut = try await makeSUT()

        // Given
        let created = try await sut.create(name: "원래 이름")
        let updated = Folder(
            id: created.id,
            name: "수정된 이름",
            createdAt: created.createdAt,
            isDeletable: created.isDeletable,
            deletedAt: created.deletedAt
        )

        // When
        let result = try await sut.update(updated)

        // Then
        XCTAssertEqual(result.name, "수정된 이름")
    }

    func test_존재하지않는폴더를_업데이트요청시_updateFailed를던진다() async throws {
        let sut = try await makeSUT()
        let nonExistent = Folder(name: "존재하지 않는 폴더")

        // When & Then
        do {
            _ = try await sut.update(nonExistent)
            XCTFail("FolderRepositoryError.updateFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .updateFailed = error else {
                return XCTFail("예상한 에러는 FolderRepositoryError.updateFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
    }

    func test_태스크가취소된상태에서_업데이트요청시_cancelled를던진다() async throws {
        let sut = try await makeSUT()
        let folder = Folder(name: "무관")

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.update(folder)
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("FolderRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? FolderRepositoryError else {
                return XCTFail("예상한 에러는 FolderRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
    }
}
