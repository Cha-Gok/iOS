@testable import Domain
import Core
import XCTest

final class UpdateFolderUseCaseTest: XCTestCase {}

// MARK: - 성공 케이스

extension UpdateFolderUseCaseTest {
    func test_정상상태_폴더수정시_업데이트된폴더를반환한다() async throws {
        let repository = MockFolderRepository()
        let sut = DefaultUpdateFolderUseCase(repository: repository)

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
        let result = try await sut.execute(updatedFolder)

        // Then
        XCTAssertEqual(result.name, "New Name")
        XCTAssertEqual(result.id, originalFolder.id)
        await repository.verify()
    }
}

// MARK: - 에러 케이스

extension UpdateFolderUseCaseTest {
    func test_너무긴이름상태_폴더수정시_invalidLengthName에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultUpdateFolderUseCase(repository: repository)

        // Given
        await repository.expectUpdate(callCount: 0)
        let tooLongName = String(repeating: "a", count: 51)
        let folder: Folder = .init(name: tooLongName)

        // When & Then
        do {
            _ = try await sut.execute(folder)
            XCTFail("UpdateFolderUseCaseError.invalidLengthName 에러를 throw 해야 합니다.")
        } catch {
            guard case .invalidLengthName = error else {
                return XCTFail(
                    "예상한 에러는 UpdateFolderUseCaseError.invalidLengthName 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_유효하지않은이름상태_폴더수정시_invalidName에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultUpdateFolderUseCase(repository: repository)

        // Given
        await repository.expectUpdate(callCount: 0)
        let invalidNames = ["", " ", "  \n  ", " 새폴더", "새 폴더 ", "  새 폴더  "]

        // When & Then
        await withTaskGroup(of: Void.self) { group in
            for name in invalidNames {
                group.addTask {
                    let folder = Folder(name: name)
                    do {
                        _ = try await sut.execute(folder)
                        XCTFail(
                            "UpdateFolderUseCaseError.invalidName 에러를 throw 해야 합니다. (input: '\(name)')"
                        )
                    } catch {
                        guard case .invalidName = error as? UpdateFolderUseCaseError else {
                            return XCTFail(
                                "예상한 에러는 UpdateFolderUseCaseError.invalidName 이지만, 실제 받은 에러는 \(error) 입니다. (input: '\(name)')"
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
        let sut = DefaultUpdateFolderUseCase(repository: repository)

        // Given
        let folder = Folder(name: "Any")
        await repository.setUpdateResult(.failure(.notFound))
        await repository.expectUpdate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute(folder)
            XCTFail("UpdateFolderUseCaseError.notFound 에러를 throw 해야 합니다.")
        } catch {
            guard case .notFound = error else {
                return XCTFail(
                    "예상한 에러는 UpdateFolderUseCaseError.notFound 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_중복된이름상태_폴더수정시_duplicateName에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultUpdateFolderUseCase(repository: repository)

        // Given
        let folder = Folder(name: "New Name")
        await repository.setUpdateResult(.failure(.duplicateName))
        await repository.expectUpdate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute(folder)
            XCTFail("UpdateFolderUseCaseError.duplicateName 에러를 throw 해야 합니다.")
        } catch {
            guard case .duplicateName = error else {
                return XCTFail(
                    "예상한 에러는 UpdateFolderUseCaseError.duplicateName 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_리포지토리수정실패상태_폴더수정시_updateFailed에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultUpdateFolderUseCase(repository: repository)

        // Given
        let folder = Folder(name: "Any")
        await repository.setUpdateResult(.failure(.updateFailed))
        await repository.expectUpdate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute(folder)
            XCTFail("UpdateFolderUseCaseError.updateFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .updateFailed = error else {
                return XCTFail(
                    "예상한 에러는 UpdateFolderUseCaseError.updateFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_리포지토리알수없는에러상태_폴더수정시_unknown에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultUpdateFolderUseCase(repository: repository)

        // Given
        let folder = Folder(name: "Any")
        struct DummyError: Error {}
        let expectedError = DummyError()
        await repository.setUpdateResult(.failure(.unknown(expectedError)))
        await repository.expectUpdate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute(folder)
            XCTFail("UpdateFolderUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let wrappedError) = error else {
                return XCTFail(
                    "예상한 에러는 UpdateFolderUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }

            guard let repoError = wrappedError as? FolderRepositoryError,
                  case .unknown(let underlyingError) = repoError
            else {
                return XCTFail("Unknown 에러 내부에는 FolderRepositoryError.unknown이 포함되어야 합니다.")
            }
            XCTAssertTrue(underlyingError is DummyError)
        }

        await repository.verify()
    }
}

// MARK: - 취소 케이스

extension UpdateFolderUseCaseTest {
    func test_작업취소상태_폴더수정시_cancelled에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultUpdateFolderUseCase(repository: repository)

        // Given
        let folder = Folder(name: "Any")
        await repository.setUpdateResult(.failure(.cancelled))
        await repository.expectUpdate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute(folder)
            XCTFail("UpdateFolderUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error else {
                return XCTFail(
                    "예상한 에러는 UpdateFolderUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_태스크이미취소상태_폴더수정시_즉시cancelled에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultUpdateFolderUseCase(repository: repository)

        // Given
        let folder = Folder(name: "Any")
        await repository.setUpdateResult(.success(folder))
        await repository.expectUpdate(callCount: 0)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await sut.execute(folder)
        }

        do {
            _ = try await task.value
            XCTFail("UpdateFolderUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? UpdateFolderUseCaseError else {
                return XCTFail(
                    "예상한 에러는 UpdateFolderUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }
}
