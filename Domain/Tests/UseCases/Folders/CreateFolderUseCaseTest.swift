@testable import Domain
import XCTest

final class CreateFolderUseCaseTest: XCTestCase {}

// MARK: - 성공 케이스

extension CreateFolderUseCaseTest {
    func test_정상상태_폴더생성시_생성된폴더를반환한다() async throws {
        // Given
        let expectedName = "New Folder"
        let expectedFolder = Folder.stub(path: URL(fileURLWithPath: "/test"), name: expectedName)
        let repository = MockFolderRepository()
        await repository.setCreateResult(.success(expectedFolder))
        await repository.expectCreate(name: expectedName, callCount: 1)

        let useCase = DefaultCreateFolderUseCase(repository: repository)

        // When
        let folder = try await useCase.execute(name: expectedName)

        // Then
        XCTAssertEqual(folder.name, expectedName)
        XCTAssertEqual(folder.id, expectedFolder.id)
        await repository.verify()
    }
}

// MARK: - 에러 케이스

extension CreateFolderUseCaseTest {
    func test_유효하지않은이름상태_폴더생성시_invalidName에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.expectCreate(callCount: 0)

        let useCase = DefaultCreateFolderUseCase(repository: repository)
        let invalidNames = ["", " ", "  \n  ", " 새폴더", "새 폴더 ", "  새 폴더  "]

        // When & Then
        await withTaskGroup(of: Void.self) { group in
            for name in invalidNames {
                group.addTask {
                    do {
                        _ = try await useCase.execute(name: name)
                        XCTFail("유효하지 않은 이름의 경우 .invalidName 에러가 발생해야 합니다. (input: '\(name)')")
                    } catch CreateFolderUseCaseError.invalidName {
                        // Success
                    } catch {
                        XCTFail("Expected .invalidName, got \(error) for name: '\(name)'")
                    }
                }
            }
        }

        await repository.verify()
    }

    func test_너무긴이름상태_폴더생성시_invalidLengthName에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.expectCreate(callCount: 0)

        let useCase = DefaultCreateFolderUseCase(repository: repository)
        let tooLongName = String(repeating: "a", count: 51)

        // When & Then
        do {
            _ = try await useCase.execute(name: tooLongName)
            XCTFail("invalidLengthName이 발생해야 합니다. (input: \(tooLongName))")
        } catch CreateFolderUseCaseError.invalidLengthName {
            // Success
        } catch {
            XCTFail("Expected .invalidLengthName, got \(error) for name: \(tooLongName)")
        }

        await repository.verify()
    }

    func test_중복된이름상태_폴더생성시_duplicateName에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.setCreateResult(.failure(.duplicateName))
        await repository.expectCreate(callCount: 1)

        let useCase = DefaultCreateFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(name: "Existing Folder")
            XCTFail("중복 이름인 경우 .duplicateName 에러가 발생해야 합니다.")
        } catch CreateFolderUseCaseError.duplicateName {
            // Success
        } catch {
            XCTFail("Expected .duplicateName, got \(error)")
        }

        await repository.verify()
    }

    func test_리포지토리생성실패상태_폴더생성시_createFailed에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.setCreateResult(.failure(.createFailed))
        await repository.expectCreate(callCount: 1)

        let useCase = DefaultCreateFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(name: "New Folder")
            XCTFail("생성 실패의 경우 .createFailed 에러가 발생해야 합니다.")
        } catch CreateFolderUseCaseError.createFailed {
            // Success
        } catch {
            XCTFail("Expected .createFailed, got \(error)")
        }

        await repository.verify()
    }

    func test_리포지토리알수없는에러상태_폴더생성시_unknown에러를던진다() async {
        // Given
        struct Dummy: Error {}
        let dummyError = Dummy()
        let repository = MockFolderRepository()
        await repository.setCreateResult(.failure(.unknown(dummyError)))
        await repository.expectCreate(callCount: 1)

        let useCase = DefaultCreateFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(name: "Unknown Test")
            XCTFail("알 수 없는 에러 발생 시 .unknown으로 래핑되어야 합니다.")
        } catch CreateFolderUseCaseError.unknown(let error) {
            guard let repoError = error as? FolderRepositoryError else {
                return XCTFail("Unknown 에러 내부에는 FolderRepositoryError가 포함되어야 합니다.")
            }

            switch repoError {
            case .unknown(let underlyingError):
                XCTAssertTrue(underlyingError is Dummy)
            default:
                XCTFail("Expected .unknown underlying error, but got \(repoError)")
            }
        } catch {
            XCTFail("Expected .unknown, got \(error)")
        }

        await repository.verify()
    }
}

// MARK: - 취소 케이스

extension CreateFolderUseCaseTest {
    func test_작업취소상태_폴더생성시_cancelled에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.setCreateResult(.failure(.cancelled))
        await repository.expectCreate(callCount: 1)

        let useCase = DefaultCreateFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(name: "Existing Folder")
            XCTFail("작업 취소의 경우 .cancelled 에러가 발생해야 합니다.")
        } catch CreateFolderUseCaseError.cancelled {
            // Success
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }

        await repository.verify()
    }

    func test_태스크이미취소상태_폴더생성시_즉시cancelled에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.setCreateResult(.success(Folder.stub(path: URL.applicationSupportDirectory, name: "test")))
        await repository.expectCreate(callCount: 0)

        let useCase = DefaultCreateFolderUseCase(repository: repository)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await useCase.execute(name: "Cancel Test")
        }

        do {
            _ = try await task.value
            XCTFail("작업이 즉시 취소되었으므로 .cancelled 에러가 발생해야 합니다.")
        } catch CreateFolderUseCaseError.cancelled {
            // Success
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }

        await repository.verify()
    }
}
