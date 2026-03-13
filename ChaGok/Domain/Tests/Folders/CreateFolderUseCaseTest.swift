import XCTest
@testable import Domain

final class CreateFolderUseCaseTest: XCTestCase {
    typealias UseCaseError = CreateFolderUseCaseError
}

// MARK: - 성공 케이스

extension CreateFolderUseCaseTest {

    func test_폴더_생성_성공_생성된폴더를반환한다() async throws {
        // Given
        let expectedName = "New Folder"
        let expectedFolder = Folder(path: URL(fileURLWithPath: "/test"), name: expectedName)
        let repository = MockFolderRepository()
        await repository.setCreateResult(.success(expectedFolder))
        await repository.expectCreate(callCount: 1)

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

    func test_폴더_생성_이름이비어있을때_invalidName에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.expectCreate(callCount: 0)

        let useCase = DefaultCreateFolderUseCase(repository: repository)
        let invalidNames = ["", " ", "  \n  "]

        // When & Then
        await withTaskGroup(of: Void.self) { group in
            for name in invalidNames {
                group.addTask {
                    do {
                        _ = try await useCase.execute(name: name)
                        XCTFail("이름이 비어있는 경우 .invalidName 에러가 발생해야 합니다. (input: '\(name)')")
                    } catch UseCaseError.invalidName {
                        // Success
                    } catch {
                        XCTFail("Expected .invalidName, got \(error) for name: '\(name)'")
                    }
                }
            }
        }

        await repository.verify()
    }

    func test_폴더_생성_이름이너무길때_invalidLengthName에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.expectCreate(callCount: 0)

        let useCase = DefaultCreateFolderUseCase(repository: repository)
        let tooLongName = String(repeating: "a", count: 51)

        // When & Then
        do {
            _ = try await useCase.execute(name: tooLongName)
            XCTFail("invalidLengthName이 발생해야 합니다. (input: \(tooLongName))")
        } catch UseCaseError.invalidLengthName {
            // Success
        } catch {
            XCTFail("Expected .invalidLengthName, got \(error) for name: \(tooLongName)")
        }

        await repository.verify()
    }

    func test_폴더_생성_리포지토리중복이름에러시_duplicateName에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.setCreateResult(.failure(.duplicateName))
        await repository.expectCreate(callCount: 1)

        let useCase = DefaultCreateFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(name: "Existing Folder")
            XCTFail("중복 이름인 경우 .duplicateName 에러가 발생해야 합니다.")
        } catch UseCaseError.duplicateName {
            // Success
        } catch {
            XCTFail("Expected .duplicateName, got \(error)")
        }

        await repository.verify()
    }

    func test_폴더_생성_리포지토리생성실패시_createFailed에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.setCreateResult(.failure(.createFailed))
        await repository.expectCreate(callCount: 1)

        let useCase = DefaultCreateFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(name: "New Folder")
            XCTFail("생성 실패의 경우 .createFailed 에러가 발생해야 합니다.")
        } catch UseCaseError.createFailed {
            // Success
        } catch {
            XCTFail("Expected .createFailed, got \(error)")
        }

        await repository.verify()
    }

    func test_폴더_생성_리포지토리찾을수없음시_unknown에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.setCreateResult(.failure(.notFound))
        await repository.expectCreate(callCount: 1)

        let useCase = DefaultCreateFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(name: "Existing Folder")
            XCTFail("찾을 수 없을 시 .unknown으로 래핑되어야 합니다.")
        } catch UseCaseError.unknown(let error) {
            guard let repoError = error as? FolderRepositoryError else {
                return XCTFail("Unknown 에러 내부는 FolderRepositoryError가 적용되어야 합니다.")
            }

            switch repoError {
            case .notFound:
                break // Success
            default:
                XCTFail("Expected .notFound, but got \(repoError)")
            }
        } catch {
            XCTFail("Expected .unknown, got \(error)")
        }

        await repository.verify()
    }

    func test_폴더_생성_리포지토리수정실패시_unknown에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.setCreateResult(.failure(.updateFailed))
        await repository.expectCreate(callCount: 1)

        let useCase = DefaultCreateFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(name: "Existing Folder")
            XCTFail("찾을 수 없을 시 .unknown으로 래핑되어야 합니다.")
        } catch UseCaseError.unknown(let error) {
            guard let repoError = error as? FolderRepositoryError else {
                return XCTFail("Unknown 에러 내부는 FolderRepositoryError가 적용되어야 합니다.")
            }

            switch repoError {
            case .updateFailed:
                break // Success
            default:
                XCTFail("Expected .updateFailed, but got \(repoError)")
            }
        } catch {
            XCTFail("Expected .unknown, got \(error)")
        }

        await repository.verify()
    }

    func test_폴더_생성_리포지토리조회실패시_unknown에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.setCreateResult(.failure(.fetchFailed))
        await repository.expectCreate(callCount: 1)

        let useCase = DefaultCreateFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(name: "Existing Folder")
            XCTFail("찾을 수 없을 시 .unknown으로 래핑되어야 합니다.")
        } catch UseCaseError.unknown(let error) {
            guard let repoError = error as? FolderRepositoryError else {
                return XCTFail("Unknown 에러 내부는 FolderRepositoryError가 적용되어야 합니다.")
            }

            switch repoError {
            case .fetchFailed:
                break // Success
            default:
                XCTFail("Expected .fetchFailed, but got \(repoError)")
            }
        } catch {
            XCTFail("Expected .unknown, got \(error)")
        }

        await repository.verify()
    }

    func test_폴더_생성_리포지토리알수없는에러시_unknown에러를던진다() async {
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
        } catch UseCaseError.unknown(let error) {
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

    func test_폴더_생성_리포지토리취소시_cancelled에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.setCreateResult(.failure(.cancelled))
        await repository.expectCreate(callCount: 1)

        let useCase = DefaultCreateFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(name: "Existing Folder")
            XCTFail("작업 취소의 경우 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }

        await repository.verify()
    }

    func test_폴더_생성_작업이미취소시_즉시cancelled에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.setCreateResult(.success(Folder(path: URL.applicationSupportDirectory, name: "test")))
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
        } catch UseCaseError.cancelled {
            // Success
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }

        await repository.verify()
    }
}
