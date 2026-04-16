@testable import Domain
import Core
import DomainTesting
import XCTest

final class FolderUseCaseTest: XCTestCase {}

// MARK: - create(name:) 성공 케이스

extension FolderUseCaseTest {
    func test_정상상태_폴더생성시_생성된폴더를반환한다() async throws {
        let repository = MockFolderRepository()
        let sut = DefaultFolderUseCase(repository: repository)

        // Given
        let expectedName = "New Folder"
        let expectedFolder = Folder.stub(name: expectedName)
        await repository.setCreateResult(.success(expectedFolder))
        await repository.expectCreate(name: expectedName, isDeletable: true, callCount: 1)

        // When
        let folder = try await sut.create(name: expectedName)

        // Then
        XCTAssertEqual(folder.name, expectedName)
        XCTAssertEqual(folder.id, expectedFolder.id)
        await repository.verify()
    }

    func test_기본폴더이름상태_폴더생성시_reservedName에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultFolderUseCase(repository: repository)

        // Given
        await repository.expectCreate(callCount: 0)

        // When & Then
        do {
            _ = try await sut.create(name: Policy.defaultFolderName)
            XCTFail("FolderUseCaseError.reservedName 에러를 throw 해야 합니다.")
        } catch FolderUseCaseError.reservedName {
            // Success
        } catch {
            XCTFail("예상한 에러는 FolderUseCaseError.reservedName 이지만, 실제 받은 에러는 \(error) 입니다.")
        }

        await repository.verify()
    }
}

// MARK: - create(name:) 에러 케이스

extension FolderUseCaseTest {
    func test_유효하지않은이름상태_폴더생성시_invalidName에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultFolderUseCase(repository: repository)

        // Given
        await repository.expectCreate(callCount: 0)
        let invalidNames = ["", " ", "  \n  ", " 새폴더", "새 폴더 ", "  새 폴더  "]

        // When & Then
        await withTaskGroup(of: Void.self) { group in
            for name in invalidNames {
                group.addTask {
                    do {
                        _ = try await sut.create(name: name)
                        XCTFail("FolderUseCaseError.invalidName 에러를 throw 해야 합니다. (input: '\(name)')")
                    } catch {
                        guard case .invalidName = error as? FolderUseCaseError else {
                            return XCTFail(
                                "예상한 에러는 FolderUseCaseError.invalidName 이지만, 실제 받은 에러는 \(error) 입니다. (input: '\(name)')"
                            )
                        }
                    }
                }
            }
        }

        await repository.verify()
    }

    func test_너무긴이름상태_폴더생성시_invalidLengthName에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultFolderUseCase(repository: repository)

        // Given
        await repository.expectCreate(callCount: 0)
        let tooLongName = String(repeating: "a", count: 51)

        // When & Then
        do {
            _ = try await sut.create(name: tooLongName)
            XCTFail("FolderUseCaseError.invalidLengthName 에러를 throw 해야 합니다.")
        } catch {
            guard case .invalidLengthName = error else {
                return XCTFail(
                    "예상한 에러는 FolderUseCaseError.invalidLengthName 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_중복된이름상태_폴더생성시_duplicateName에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultFolderUseCase(repository: repository)

        // Given
        await repository.setCreateResult(.failure(.duplicateName))
        await repository.expectCreate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.create(name: "Existing Folder")
            XCTFail("FolderUseCaseError.duplicateName 에러를 throw 해야 합니다.")
        } catch {
            guard case .duplicateName = error else {
                return XCTFail(
                    "예상한 에러는 FolderUseCaseError.duplicateName 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_리포지토리생성실패상태_폴더생성시_createFailed에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultFolderUseCase(repository: repository)

        // Given
        await repository.setCreateResult(.failure(.createFailed))
        await repository.expectCreate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.create(name: "New Folder")
            XCTFail("FolderUseCaseError.createFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .createFailed = error else {
                return XCTFail(
                    "예상한 에러는 FolderUseCaseError.createFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_리포지토리알수없는에러상태_폴더생성시_unknown에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultFolderUseCase(repository: repository)

        // Given
        struct DummyError: Error {}
        let expectedError = DummyError()
        await repository.setCreateResult(.failure(.unknown(expectedError)))
        await repository.expectCreate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.create(name: "Unknown Test")
            XCTFail("FolderUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let wrappedError) = error else {
                return XCTFail(
                    "예상한 에러는 FolderUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
            XCTAssertTrue(wrappedError is DummyError)
        }

        await repository.verify()
    }
}

// MARK: - create(name:) 취소 케이스

extension FolderUseCaseTest {
    func test_작업취소상태_폴더생성시_cancelled에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultFolderUseCase(repository: repository)

        // Given
        await repository.setCreateResult(.failure(.cancelled))
        await repository.expectCreate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.create(name: "Existing Folder")
            XCTFail("FolderUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error else {
                return XCTFail(
                    "예상한 에러는 FolderUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_태스크이미취소상태_폴더생성시_즉시cancelled에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultFolderUseCase(repository: repository)

        // Given
        await repository.setCreateResult(.success(Folder.stub(name: "test")))
        await repository.expectCreate(callCount: 0)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await sut.create(name: "Cancel Test")
        }

        do {
            _ = try await task.value
            XCTFail("FolderUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? FolderUseCaseError else {
                return XCTFail(
                    "예상한 에러는 FolderUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }
}

// MARK: - fetchAll() 성공 케이스

extension FolderUseCaseTest {
    func test_정상상태_fetchAll호출시_삭제되지않은_모든폴더를반환한다() async throws {
        let repository = MockFolderRepository()
        let sut = DefaultFolderUseCase(repository: repository)

        // Given
        let expectedFolders = [
            Folder.stub(name: "기본 폴더", isDeletable: false),
            Folder.stub(name: "휴지통에 있는 폴더", deletedAt: Date()),
            Folder.stub(name: "Folder 1", isDeletable: true),
            Folder.stub(name: "Folder 2", isDeletable: true)
        ]
        await repository.setFetchAllResult(.success(expectedFolders))
        await repository.expectFetchAll(callCount: 1)

        // When
        let folders = try await sut.fetchAll()

        // Then
        XCTAssertEqual(folders.count, 3)
        XCTAssertEqual(folders[0].name, "기본 폴더")
        XCTAssertEqual(folders[1].name, "Folder 1")
        XCTAssertEqual(folders[2].name, "Folder 2")
        await repository.verify()
    }

    func test_정상상태_fetchDeletableFolders호출시_기본과삭제된폴더를제외한_폴더목록만반환한다() async throws {
        let repository = MockFolderRepository()
        let sut = DefaultFolderUseCase(repository: repository)

        // Given
        let expectedFolders = [
            Folder.stub(name: "기본 폴더", isDeletable: false),
            Folder.stub(name: "휴지통에 있는 폴더", deletedAt: Date()),
            Folder.stub(name: "Folder 1", isDeletable: true),
            Folder.stub(name: "Folder 2", isDeletable: true)
        ]
        await repository.setFetchAllResult(.success(expectedFolders))
        await repository.expectFetchAll(callCount: 1)

        // When
        let folders = try await sut.fetchDeletableFolders()

        // Then
        XCTAssertEqual(folders.count, 2)
        XCTAssertEqual(folders[0].name, "Folder 1")
        XCTAssertEqual(folders[1].name, "Folder 2")
        await repository.verify()
    }
}

// MARK: - fetchAll() 에러 케이스

extension FolderUseCaseTest {
    func test_리포지토리조회실패상태_폴더조회시_fetchFailed에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultFolderUseCase(repository: repository)

        // Given
        await repository.setFetchAllResult(.failure(.fetchFailed))
        await repository.expectFetchAll(callCount: 1)

        // When & Then
        do {
            _ = try await sut.fetchAll()
            XCTFail("FolderUseCaseError.fetchFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .fetchFailed = error else {
                return XCTFail(
                    "예상한 에러는 FolderUseCaseError.fetchFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_태스크이미취소상태_폴더조회시_즉시cancelled에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultFolderUseCase(repository: repository)

        // Given
        await repository.setFetchAllResult(.success([]))
        await repository.expectFetchAll(callCount: 0)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await sut.fetchAll()
        }

        do {
            _ = try await task.value
            XCTFail("FolderUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? FolderUseCaseError else {
                return XCTFail(
                    "예상한 에러는 FolderUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }
}

// MARK: - update(_:) 성공 케이스

extension FolderUseCaseTest {
    func test_정상상태_폴더수정시_업데이트된폴더를반환한다() async throws {
        let repository = MockFolderRepository()
        let sut = DefaultFolderUseCase(repository: repository)

        // Given
        let originalFolder = Folder.stub(name: "Old Name")
        let updatedFolder = Folder.stub(
            id: originalFolder.id,
            name: "New Name",
            createdAt: originalFolder.createdAt,
            content: originalFolder.content,
            isDeletable: originalFolder.isDeletable,
            deletedAt: originalFolder.deletedAt
        )

        await repository.setUpdateResult(.success(updatedFolder))
        await repository.expectUpdate(folderID: updatedFolder.id, callCount: 1)

        // When
        let result = try await sut.update(updatedFolder)

        // Then
        XCTAssertEqual(result.name, "New Name")
        XCTAssertEqual(result.id, originalFolder.id)
        await repository.verify()
    }
}

// MARK: - update(_:) 에러 케이스

extension FolderUseCaseTest {
    func test_너무긴이름상태_폴더수정시_invalidLengthName에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultFolderUseCase(repository: repository)

        // Given
        await repository.expectUpdate(callCount: 0)
        let tooLongName = String(repeating: "a", count: 51)
        let folder = Folder(name: tooLongName)

        // When & Then
        do {
            _ = try await sut.update(folder)
            XCTFail("FolderUseCaseError.invalidLengthName 에러를 throw 해야 합니다.")
        } catch {
            guard case .invalidLengthName = error else {
                return XCTFail(
                    "예상한 에러는 FolderUseCaseError.invalidLengthName 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_유효하지않은이름상태_폴더수정시_invalidName에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultFolderUseCase(repository: repository)

        // Given
        await repository.expectUpdate(callCount: 0)
        let invalidNames = ["", " ", "  \n  ", " 새폴더", "새 폴더 ", "  새 폴더  "]

        // When & Then
        await withTaskGroup(of: Void.self) { group in
            for name in invalidNames {
                group.addTask {
                    let folder = Folder(name: name)
                    do {
                        _ = try await sut.update(folder)
                        XCTFail("FolderUseCaseError.invalidName 에러를 throw 해야 합니다. (input: '\(name)')")
                    } catch {
                        guard case .invalidName = error as? FolderUseCaseError else {
                            return XCTFail(
                                "예상한 에러는 FolderUseCaseError.invalidName 이지만, 실제 받은 에러는 \(error) 입니다. (input: '\(name)')"
                            )
                        }
                    }
                }
            }
        }

        await repository.verify()
    }

    func test_폴더미존재상태_폴더수정시_notFound에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultFolderUseCase(repository: repository)

        // Given
        let folder = Folder(name: "Any")
        await repository.setUpdateResult(.failure(.notFound))
        await repository.expectUpdate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.update(folder)
            XCTFail("FolderUseCaseError.notFound 에러를 throw 해야 합니다.")
        } catch {
            guard case .notFound = error else {
                return XCTFail(
                    "예상한 에러는 FolderUseCaseError.notFound 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_중복된이름상태_폴더수정시_duplicateName에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultFolderUseCase(repository: repository)

        // Given
        let folder = Folder(name: "New Name")
        await repository.setUpdateResult(.failure(.duplicateName))
        await repository.expectUpdate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.update(folder)
            XCTFail("FolderUseCaseError.duplicateName 에러를 throw 해야 합니다.")
        } catch {
            guard case .duplicateName = error else {
                return XCTFail(
                    "예상한 에러는 FolderUseCaseError.duplicateName 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_리포지토리수정실패상태_폴더수정시_updateFailed에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultFolderUseCase(repository: repository)

        // Given
        let folder = Folder(name: "Any")
        await repository.setUpdateResult(.failure(.updateFailed))
        await repository.expectUpdate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.update(folder)
            XCTFail("FolderUseCaseError.updateFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .updateFailed = error else {
                return XCTFail(
                    "예상한 에러는 FolderUseCaseError.updateFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_태스크이미취소상태_폴더수정시_즉시cancelled에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultFolderUseCase(repository: repository)

        // Given
        let folder = Folder(name: "Any")
        await repository.setUpdateResult(.success(folder))
        await repository.expectUpdate(callCount: 0)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await sut.update(folder)
        }

        do {
            _ = try await task.value
            XCTFail("FolderUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? FolderUseCaseError else {
                return XCTFail(
                    "예상한 에러는 FolderUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }
}
