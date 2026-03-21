@testable import Data
import CoreData
import Domain
import XCTest

final class DefaultFolderRepositoryTests: XCTestCase {}

// MARK: - 폴더 생성 에러 및 취소 케이스

extension DefaultFolderRepositoryTests {
    func test_정상적인이름일때_폴더생성시_성공한폴더를반환한다() async throws {
        let mock = MockFolderLocalDataBase()
        let sut = DefaultFolderRepository(database: mock)
        let name = "새 폴더"
        let expectedFolder = Folder(id: UUID(), path: URL.applicationSupportDirectory, name: name, createdAt: Date.now)

        // Given
        await mock.setCreateResult(.success(expectedFolder))
        await mock.expectCreate(callCount: 1)

        // When
        let result = try await sut.create(name: name)

        // Then
        XCTAssertEqual(result.name, name)
        XCTAssertEqual(result.id, expectedFolder.id)
        await mock.verify()
    }

    func test_데이터소스에서_생성실패에러가나면_createFailed를던진다() async throws {
        let mock = MockFolderLocalDataBase()
        let sut = DefaultFolderRepository(database: mock)

        // Given
        await mock.setCreateResult(.failure(FolderRepositoryError.createFailed))
        await mock.expectCreate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.create(name: "실패할 폴더")
            XCTFail("FolderRepositoryError.createFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .createFailed = error else {
                return XCTFail("예상한 에러는 FolderRepositoryError.createFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await mock.verify()
    }

    func test_태스크가취소된상태에서_생성요청시_cancelled를던진다() async throws {
        let mock = MockFolderLocalDataBase()
        let sut = DefaultFolderRepository(database: mock)

        // Given
        await mock.expectCreate(callCount: 0)

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
        await mock.verify()
    }
}

// MARK: - 폴더 조회 성공 및 실패 케이스

extension DefaultFolderRepositoryTests {
    func test_폴더목록이존재할때_전체조회시_폴더리스트를반환한다() async throws {
        let mock = MockFolderLocalDataBase()
        let sut = DefaultFolderRepository(database: mock)
        let expectedFolders = [
            Folder(id: UUID(), path: URL.applicationSupportDirectory, name: "폴더1", createdAt: Date.now),
            Folder(id: UUID(), path: URL.applicationSupportDirectory, name: "폴더2", createdAt: Date.now)
        ]

        // Given
        await mock.setFetchResult(.success(expectedFolders))
        await mock.expectFetch(callCount: 1)

        // When
        let result = try await sut.fetchAll()

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first?.name, "폴더1")
        await mock.verify()
    }

    func test_데이터소스에서_조회실패에러가나면_fetchFailed를던진다() async throws {
        let mock = MockFolderLocalDataBase()
        let sut = DefaultFolderRepository(database: mock)

        // Given
        await mock.setFetchResult(.failure(FolderRepositoryError.fetchFailed))
        await mock.expectFetch(callCount: 1)

        // When & Then
        do {
            _ = try await sut.fetchAll()
            XCTFail("FolderRepositoryError.fetchFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .fetchFailed = error else {
                return XCTFail("예상한 에러는 FolderRepositoryError.fetchFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await mock.verify()
    }

    func test_태스크가취소된상태에서_전체조회요청시_cancelled를던진다() async throws {
        let mock = MockFolderLocalDataBase()
        let sut = DefaultFolderRepository(database: mock)

        // Given
        await mock.expectFetch(callCount: 0)

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
        await mock.verify()
    }
}

// MARK: - 폴더 수정 성공 및 실패 케이스

extension DefaultFolderRepositoryTests {
    func test_폴더정보가수정되었을때_업데이트요청시_수정된폴더를반환한다() async throws {
        let mock = MockFolderLocalDataBase()
        let sut = DefaultFolderRepository(database: mock)
        let folder = Folder(id: UUID(), path: URL.applicationSupportDirectory, name: "수정된 이름", createdAt: Date.now)

        // Given
        await mock.setUpdateResult(.success(folder))
        await mock.expectUpdate(callCount: 1)

        // When
        let result = try await sut.update(folder)

        // Then
        XCTAssertEqual(result.name, "수정된 이름")
        await mock.verify()
    }

    func test_데이터소스에서_업데이트실패에러가나면_updateFailed를던진다() async throws {
        let mock = MockFolderLocalDataBase()
        let sut = DefaultFolderRepository(database: mock)
        let dummyFolder = Folder(id: UUID(), path: URL.applicationSupportDirectory, name: "무관", createdAt: Date.now)

        // Given
        // 데이터 소스에서 조회 실패(notFound)가 발생해도 리포지토리는 updateFailed로 변환해야 함
        await mock.setUpdateResult(.failure(FolderRepositoryError.notFound))
        await mock.expectUpdate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.update(dummyFolder)
            XCTFail("FolderRepositoryError.updateFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .updateFailed = error else {
                return XCTFail("예상한 에러는 FolderRepositoryError.updateFailed 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
        await mock.verify()
    }

    func test_태스크가취소된상태에서_업데이트요청시_cancelled를던진다() async throws {
        let mock = MockFolderLocalDataBase()
        let sut = DefaultFolderRepository(database: mock)
        let folder = Folder(id: UUID(), path: URL.applicationSupportDirectory, name: "무관", createdAt: Date.now)

        // Given
        await mock.expectUpdate(callCount: 0)

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
        await mock.verify()
    }
}
