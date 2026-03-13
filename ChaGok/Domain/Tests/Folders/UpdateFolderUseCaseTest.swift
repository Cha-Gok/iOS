import XCTest
@testable import Domain

final class UpdateFolderUseCaseTest: XCTestCase {
    typealias UseCaseError = UpdateFolderUseCaseError
}

// MARK: - 성공 케이스

extension UpdateFolderUseCaseTest {

    func test_폴더_수정_성공_업데이트된폴더를반환한다() async throws {
        // Given
        let originalFolder = Folder(path: URL(fileURLWithPath: "/test"), name: "Old Name")
        let updatedFolder = Folder(
            id: originalFolder.id,
            path: originalFolder.path,
            name: "New Name",
            createdAt: originalFolder.createdAt
        )

        let repository = MockFolderRepository()
        await repository.setUpdateResult(.success(updatedFolder))
        await repository.expectUpdate(callCount: 1)

        let useCase = DefaultUpdateFolderUseCase(repository: repository)

        // When
        let result = try await useCase.execute(originalFolder)

        // Then
        XCTAssertEqual(result.name, "New Name")
        XCTAssertEqual(result.id, originalFolder.id)
        XCTAssertEqual(result.path, originalFolder.path)
        XCTAssertEqual(result.createdAt, originalFolder.createdAt)
        await repository.verify()
    }
}

// MARK: - 에러 케이스

extension UpdateFolderUseCaseTest {

    func test_폴더_수정_이름이너무길때_invalidLengthName에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.expectUpdate(callCount: 0)

        let useCase = DefaultUpdateFolderUseCase(repository: repository)
        let tooLongName = String(repeating: "a", count: 51)
        let folder: Folder = .init(path: URL.applicationSupportDirectory, name: tooLongName)

        // When & Then
        do {
            _ = try await useCase.execute(folder)
            XCTFail("invailedLengthName이 발생해야 합니다. (input: \(tooLongName))")
        } catch UseCaseError.invalidLengthName {
            // Success
        } catch {
            XCTFail("Expected .invalidLengthName, got \(error) for name: \(tooLongName)")
        }

        await repository.verify()
    }

    func test_폴더_수정_이름이비어있을때_invalidName에러를던진다() async {
        // Given
        let repository = MockFolderRepository()
        await repository.expectUpdate(callCount: 0)

        let useCase = DefaultUpdateFolderUseCase(repository: repository)
        let invalidNames = ["", " ", "  \n  "]

        // When & Then
        await withTaskGroup(of: Void.self) { group in
            for name in invalidNames {
                group.addTask {
                    let folder = Folder(path: URL(fileURLWithPath: "/"), name: name)

                    do {
                        _ = try await useCase.execute(folder)
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

    func test_폴더_수정_리포지토리찾을수없음시_notFound에러를던진다() async {
        // Given
        let folder = Folder(path: URL(fileURLWithPath: "/test"), name: "Any")
        let repository = MockFolderRepository()
        await repository.setUpdateResult(.failure(.notFound))
        await repository.expectUpdate(callCount: 1)

        let useCase = DefaultUpdateFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(folder)
            XCTFail("폴더를 찾을 수 없는 경우 .notFound 에러가 발생해야 합니다.")
        } catch UseCaseError.notFound {
            // Success
        } catch {
            XCTFail("Expected .notFound, got \(error)")
        }

        await repository.verify()
    }

    func test_폴더_수정_리포지토리중복이름에러시_duplicateName에러를던진다() async {
        // Given
        let folder = Folder(path: URL(fileURLWithPath: "/test"), name: "New Name")
        let repository = MockFolderRepository()
        await repository.setUpdateResult(.failure(.duplicateName))
        await repository.expectUpdate(callCount: 1)

        let useCase = DefaultUpdateFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(folder)
            XCTFail("이름이 중복된 경우 .duplicateName 에러가 발생해야 합니다.")
        } catch UseCaseError.duplicateName {
            // Success
        } catch {
            XCTFail("Expected .duplicateName, got \(error)")
        }

        await repository.verify()
    }

    func test_폴더_수정_리포지토리수정실패시_updateFailed에러를던진다() async {
        // Given
        let folder = Folder(path: URL(fileURLWithPath: "/test"), name: "Any")
        let repository = MockFolderRepository()
        await repository.setUpdateResult(.failure(.updateFailed))
        await repository.expectUpdate(callCount: 1)

        let useCase = DefaultUpdateFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(folder)
            XCTFail("수정 실패 시 .updateFailed 에러가 발생해야 합니다.")
        } catch UseCaseError.updateFailed {
            // Success
        } catch {
            XCTFail("Expected .updateFailed, got \(error)")
        }

        await repository.verify()
    }

    func test_폴더_수정_리포지토리생성실패시_unknown에러를던진다() async {
        // Given
        let folder = Folder(path: URL(fileURLWithPath: "/test"), name: "Any")
        let repository = MockFolderRepository()
        await repository.setUpdateResult(.failure(.createFailed))
        await repository.expectUpdate(callCount: 1)

        let useCase = DefaultUpdateFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(folder)
            XCTFail("생성 실패 시 .unknown으로 래핑되어야 합니다.")
        } catch UseCaseError.unknown(let error) {
            guard let repoError = error as? FolderRepositoryError else {
                return XCTFail("Unknown 에러 내부는 FolderRepositoryError가 적용되어야 합니다.")
            }

            switch repoError {
            case .createFailed:
                break // Success
            default:
                XCTFail("Expected .createFailed, but got \(repoError)")
            }
        } catch {
            XCTFail("Expected .unknown, got \(error)")
        }

        await repository.verify()
    }

    func test_폴더_수정_리포지토리조회실패시_unknown에러를던진다() async {
        // Given
        let folder = Folder(path: URL(fileURLWithPath: "/test"), name: "Any")
        let repository = MockFolderRepository()
        await repository.setUpdateResult(.failure(.fetchFailed))
        await repository.expectUpdate(callCount: 1)

        let useCase = DefaultUpdateFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(folder)
            XCTFail("조회 실패 시 .unknown으로 래핑되어야 합니다.")
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

    func test_폴더_수정_리포지토리알수없는에러시_unknown에러를던진다() async {
        // Given
        let folder = Folder(path: URL(fileURLWithPath: "/test"), name: "Any")
        struct Dummy: Error {}
        let dummyError = Dummy()
        let repository = MockFolderRepository()
        await repository.setUpdateResult(.failure(.unknown(dummyError)))
        await repository.expectUpdate(callCount: 1)

        let useCase = DefaultUpdateFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(folder)
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

extension UpdateFolderUseCaseTest {

    func test_폴더_수정_리포지토리취소시_cancelled에러를던진다() async {
        // Given
        let folder = Folder(path: URL(fileURLWithPath: "/test"), name: "Any")
        let repository = MockFolderRepository()
        await repository.setUpdateResult(.failure(.cancelled))
        await repository.expectUpdate(callCount: 1)

        let useCase = DefaultUpdateFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(folder)
            XCTFail("작업 취소의 경우 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }

        await repository.verify()
    }

    func test_폴더_수정_작업이미취소시_즉시cancelled에러를던진다() async {
        // Given
        let folder = Folder(path: URL(fileURLWithPath: "/test"), name: "Any")
        let repository = MockFolderRepository()
        await repository.setUpdateResult(.success(folder))
        await repository.expectUpdate(callCount: 0)

        let useCase = DefaultUpdateFolderUseCase(repository: repository)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await useCase.execute(folder)
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
