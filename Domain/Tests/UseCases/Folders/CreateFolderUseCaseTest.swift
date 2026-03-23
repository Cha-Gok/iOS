@testable import Domain
import Core
import XCTest

final class CreateFolderUseCaseTest: XCTestCase {}

// MARK: - 성공 케이스

extension CreateFolderUseCaseTest {
    func test_정상상태_폴더생성시_생성된폴더를반환한다() async throws {
        let repository = MockFolderRepository()
        let sut = DefaultCreateFolderUseCase(repository: repository)

        // Given
        let expectedName = "New Folder"
        let expectedFolder = Folder.stub(name: expectedName)
        await repository.setCreateResult(.success(expectedFolder))
        await repository.expectCreate(name: expectedName, callCount: 1)

        // When
        let folder = try await sut.execute(name: expectedName)

        // Then
        XCTAssertEqual(folder.name, expectedName)
        XCTAssertEqual(folder.id, expectedFolder.id)
        await repository.verify()
    }
}

// MARK: - 에러 케이스

extension CreateFolderUseCaseTest {
    func test_유효하지않은이름상태_폴더생성시_invalidName에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultCreateFolderUseCase(repository: repository)

        // Given
        await repository.expectCreate(callCount: 0)
        let invalidNames = ["", " ", "  \n  ", " 새폴더", "새 폴더 ", "  새 폴더  "]

        // When & Then
        await withTaskGroup(of: Void.self) { group in
            for name in invalidNames {
                group.addTask {
                    do {
                        _ = try await sut.execute(name: name)
                        XCTFail(
                            "CreateFolderUseCaseError.invalidName 에러를 throw 해야 합니다. (input: '\(name)')"
                        )
                    } catch {
                        guard case .invalidName = error as? CreateFolderUseCaseError else {
                            return XCTFail(
                                "예상한 에러는 CreateFolderUseCaseError.invalidName 이지만, 실제 받은 에러는 \(error) 입니다. (input: '\(name)')"
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
        let sut = DefaultCreateFolderUseCase(repository: repository)

        // Given
        await repository.expectCreate(callCount: 0)
        let tooLongName = String(repeating: "a", count: 51)

        // When & Then
        do {
            _ = try await sut.execute(name: tooLongName)
            XCTFail("CreateFolderUseCaseError.invalidLengthName 에러를 throw 해야 합니다.")
        } catch {
            guard case .invalidLengthName = error else {
                return XCTFail(
                    "예상한 에러는 CreateFolderUseCaseError.invalidLengthName 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_중복된이름상태_폴더생성시_duplicateName에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultCreateFolderUseCase(repository: repository)

        // Given
        await repository.setCreateResult(.failure(.duplicateName))
        await repository.expectCreate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute(name: "Existing Folder")
            XCTFail("CreateFolderUseCaseError.duplicateName 에러를 throw 해야 합니다.")
        } catch {
            guard case .duplicateName = error else {
                return XCTFail(
                    "예상한 에러는 CreateFolderUseCaseError.duplicateName 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_리포지토리생성실패상태_폴더생성시_createFailed에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultCreateFolderUseCase(repository: repository)

        // Given
        await repository.setCreateResult(.failure(.createFailed))
        await repository.expectCreate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute(name: "New Folder")
            XCTFail("CreateFolderUseCaseError.createFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .createFailed = error else {
                return XCTFail(
                    "예상한 에러는 CreateFolderUseCaseError.createFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_리포지토리알수없는에러상태_폴더생성시_unknown에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultCreateFolderUseCase(repository: repository)

        // Given
        struct DummyError: Error {}
        let expectedError = DummyError()
        await repository.setCreateResult(.failure(.unknown(expectedError)))
        await repository.expectCreate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute(name: "Unknown Test")
            XCTFail("CreateFolderUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let wrappedError) = error else {
                return XCTFail(
                    "예상한 에러는 CreateFolderUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다."
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

extension CreateFolderUseCaseTest {
    func test_작업취소상태_폴더생성시_cancelled에러를던진다() async {
        let repository = MockFolderRepository()
        let sut = DefaultCreateFolderUseCase(repository: repository)

        // Given
        await repository.setCreateResult(.failure(.cancelled))
        await repository.expectCreate(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute(name: "Existing Folder")
            XCTFail("CreateFolderUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error else {
                return XCTFail(
                    "예상한 에러는 CreateFolderUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }

    func test_태스크이미취소상태_폴더생성시_즉시cancelled에러를던진다() async throws {
        let repository = MockFolderRepository()
        let sut = DefaultCreateFolderUseCase(repository: repository)

        // Given
        await repository.setCreateResult(
            .success(Folder.stub(name: "test"))
        )
        await repository.expectCreate(callCount: 0)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await sut.execute(name: "Cancel Test")
        }

        do {
            _ = try await task.value
            XCTFail("CreateFolderUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? CreateFolderUseCaseError else {
                return XCTFail(
                    "예상한 에러는 CreateFolderUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }

        await repository.verify()
    }
}
