import XCTest
@testable import Domain

final class UpdateFolderUseCaseTest: XCTestCase {
    typealias UseCaseError = UpdateFolderUseCaseError
}

// MARK: - Success Cases

extension UpdateFolderUseCaseTest {
    /// 성공 Case: 폴더 정보 업데이트가 정상적으로 완료될 때
    func test_execute_returnsUpdatedFolder_whenRepositorySucceeds() async throws {
        // Given
        let originalFolder = Folder(path: URL(fileURLWithPath: "/test"), name: "Old Name")
        let updatedFolder = Folder(
            id: originalFolder.id,
            path: originalFolder.path,
            name: "New Name",
            createdAt: originalFolder.createdAt
        )

        let repository = MockFolderRepository(updateBehavior: .success(updatedFolder))
        let useCase = DefaultUpdateFolderUseCase(repository: repository)

        // When
        let result = try await useCase.execute(originalFolder)

        // Then
        XCTAssertEqual(result.name, "New Name")
        XCTAssertEqual(result.id, originalFolder.id)
        XCTAssertEqual(result.path, originalFolder.path)
        XCTAssertEqual(result.createdAt, originalFolder.createdAt)
        let callCount = await repository.updateCallCount
        XCTAssertEqual(callCount, 1, "Repository의 update가 1번 호출되어야 합니다.")
    }
}

// MARK: - Error Cases

extension UpdateFolderUseCaseTest {

    /// 이름의 길이가 50을 넘어가는 경우 .invailedLength 확인
    func test_execute_throwsInvalidLength_whenNameIsTooLong() async {
        // Given
        let repository = MockFolderRepository()
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
            XCTFail("Expected .invailedLengthName, got \(error) for name: \(tooLongName)")
        }

        let callCount = await repository.updateCallCount
        XCTAssertEqual(callCount, 0, "유효하지 않은 길이일 경우 Repository를 호출하지 않아야 합니다.")
    }

    /// 유효하지 않은 이름 Case: 폴더 이름이 비어있거나 공백일 때 .invalidName 확인
    func test_execute_throwsInvalidName_whenNameIsEmpty() async {
        // Given
        let repository = MockFolderRepository()
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

        let callCount = await repository.updateCallCount
        XCTAssertEqual(callCount, 0, "유효하지 않은 이름일 경우 Repository를 호출하지 않아야 합니다.")
    }

    /// 찾을 수 없음 Case: 수정하려는 폴더가 존재하지 않을 때 .notFound 전파 확인
    func test_execute_throwsNotFound_whenRepositoryReturnsNotFound() async {
        // Given
        let folder = Folder(path: URL(fileURLWithPath: "/test"), name: "Any")
        let repository = MockFolderRepository(updateBehavior: .notFound)
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

        let callCount = await repository.updateCallCount
        XCTAssertEqual(callCount, 1, "Repository의 update가 1번 호출되어야 합니다.")
    }

    /// 이름 중복 Case: 수정하려는 이름이 이미 존재할 때 .duplicateName 전파 확인
    func test_execute_throwsDuplicateName_whenRepositoryReturnsDuplicateName() async {
        // Given
        let folder = Folder(path: URL(fileURLWithPath: "/test"), name: "New Name")
        let repository = MockFolderRepository(updateBehavior: .duplicateName)
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

        let callCount = await repository.updateCallCount
        XCTAssertEqual(callCount, 1, "Repository의 update가 1번 호출되어야 합니다.")
    }

    /// 수정 실패 Case: Repository에서 .updateFailed를 반환할 때 동일하게 전파되는지 확인
    func test_execute_throwsUpdateFailed_whenRepositoryReturnsUpdateFailed() async {
        // Given
        let folder = Folder(path: URL(fileURLWithPath: "/test"), name: "Any")
        let repository = MockFolderRepository(updateBehavior: .updateFailed)
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

        let callCount = await repository.updateCallCount
        XCTAssertEqual(callCount, 1, "Repository의 update가 1번 호출되어야 합니다.")
    }

    /// 매핑 확인 Case: Repository에서 .createFailed를 반환할 때 .unknown으로 맵핑되는지 확인
    func test_execute_throwsUnknown_whenRepositoryReturnsCreateFailed() async {
        // Given
        let folder = Folder(path: URL(fileURLWithPath: "/test"), name: "Any")
        let repository = MockFolderRepository(updateBehavior: .createFailed)
        let useCase = DefaultUpdateFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(folder)
            XCTFail("생성 실패 시 .unknown으로 래핑되어야 합니다.")
        } catch UseCaseError.unknown(let error) {
            guard let repoError = error as? FolderRepositoryError else {
                return XCTFail("Unknown 에러 내부는 FolderRepositoryError가 적용되어야 합니다. ( Typed Throws )")
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

        let callCount = await repository.updateCallCount
        XCTAssertEqual(callCount, 1, "Repository의 update가 1번 호출되어야 합니다.")
    }

    /// 매핑 확인 Case: Repository에서 .fetchFailed를 반환할 때 .unknown으로 맵핑되는지 확인
    func test_execute_throwsUnknown_whenRepositoryReturnsFetchFailed() async {
        // Given
        let folder = Folder(path: URL(fileURLWithPath: "/test"), name: "Any")
        let repository = MockFolderRepository(updateBehavior: .fetchFailed)
        let useCase = DefaultUpdateFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute(folder)
            XCTFail("조회 실패 시 .unknown으로 래핑되어야 합니다.")
        } catch UseCaseError.unknown(let error) {
            guard let repoError = error as? FolderRepositoryError else {
                return XCTFail("Unknown 에러 내부는 FolderRepositoryError가 적용되어야 합니다. ( Typed Throws )")
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

        let callCount = await repository.updateCallCount
        XCTAssertEqual(callCount, 1, "Repository의 update가 1번 호출되어야 합니다.")
    }

    /// 알 수 없는 에러 Case: Repository에서 맵핑되지 않은 에러를 던질 때 .unknown으로 래핑되는지 확인
    func test_execute_throwsUnknown_whenRepositoryThrowsUnknown() async {
        // Given
        let folder = Folder(path: URL(fileURLWithPath: "/test"), name: "Any")
        struct Dummy: Error {}
        let dummyError = Dummy()
        let repository = MockFolderRepository(updateBehavior: .unknown(dummyError))
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

        let callCount = await repository.updateCallCount
        XCTAssertEqual(callCount, 1, "Repository의 update가 1번 호출되어야 합니다.")
    }
}

// MARK: - Error Cases ( Cancelled )

extension UpdateFolderUseCaseTest {
    /// 작업 취소 Case: repository Cancelled의 경우 UseCase.Cancelled와 대칭 확인
    func test_execute_throwsCancelled_whenRepositoryReturnsCancelled() async {
        // Given
        let folder = Folder(path: URL(fileURLWithPath: "/test"), name: "Any")
        let repository = MockFolderRepository(updateBehavior: .cancelled)
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

        let callCount = await repository.updateCallCount
        XCTAssertEqual(callCount, 1, "Repository의 update가 1번 호출되어야 합니다.")
    }

    /// 취소 Case: 작업이 즉시 취소된 경우 execute 함수 내부 isCancelled를 검증한다
    func test_execute_throwsCancelled_whenTaskIsCancelledPreemptively() async {
        // Given
        let folder = Folder(path: URL(fileURLWithPath: "/test"), name: "Any")
        let useCase = DefaultUpdateFolderUseCase(
            repository: MockFolderRepository(
                updateBehavior: .success(folder)
            )
        )

        // When & Then
        let task = Task { try await useCase.execute(folder) }
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("작업이 즉시 취소되었으므로 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }

}
