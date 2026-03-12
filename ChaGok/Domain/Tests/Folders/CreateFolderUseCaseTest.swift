import XCTest
@testable import Domain

final class CreateFolderUseCaseTest: XCTestCase {
    typealias UseCaseError = CreateFolderUseCaseError
}

// MARK: - Success Cases

extension CreateFolderUseCaseTest {
    /// 성공 Case: Repository가 정상적으로 Folder를 반환할 때
    func test_execute_returnsFolder_whenRepositorySucceeds() async throws {
        // Given
        let expectedName = "New Folder"
        let expectedFolder = Folder(path: URL(fileURLWithPath: "/test"), name: expectedName)
        let useCase = DefaultCreateFolderUseCase(
            repository: MockFolderRepository(
                createBehavior: .success(expectedFolder)
            )
        )

        // When
        let folder = try await useCase.execute(name: expectedName)

        // Then
        XCTAssertEqual(folder.name, expectedName)
        XCTAssertEqual(folder.id, expectedFolder.id)
    }
}

// MARK: - Error Cases

extension CreateFolderUseCaseTest {
    /// 유효하지 않은 이름 Case: 폴더 이름이 비어있거나 공백일 때 .invalidName 확인
    func test_execute_throwsInvalidName_whenNameIsEmpty() async {
        // Given
        let useCase = DefaultCreateFolderUseCase(
            repository: MockFolderRepository()
        )
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
    }

    /// 이름의 길이가 50을 넘어가는 경우 .invailedLength 확인
    func test_execute_throwsInvalidLength_whenNameIsTooLong() async {
        let useCase = DefaultCreateFolderUseCase(
            repository: MockFolderRepository()
        )
        let tooLongName = String(repeating: "a", count: 51)

        do {
            _ = try await useCase.execute(name: tooLongName)
            XCTFail("invailedLengthName이 발생해야 합니다. (input: \(tooLongName))")
        } catch UseCaseError.invalidLengthName {
            // Success
        } catch {
            XCTFail("Expected .invailedLengthName, got \(error) for name: \(tooLongName)")
        }
    }

    /// 이름 중복 Case: 이미 같은 이름의 폴더가 존재할 때 .duplicateName 대칭 확인
    func test_execute_throwsDuplicateName_whenRepositoryReturnsDuplicateName() async {
        // Given
        let useCase = DefaultCreateFolderUseCase(
            repository: MockFolderRepository(
                createBehavior: .duplicateName
            )
        )

        // When & Then
        do {
            _ = try await useCase.execute(name: "Existing Folder")
            XCTFail("중복 이름인 경우 .duplicateName 에러가 발생해야 합니다.")
        } catch UseCaseError.duplicateName {
            // Success
        } catch {
            XCTFail("Expected .duplicateName, got \(error)")
        }
    }

    /// 생성 실패 Case: repository가 .createFailed를 반환할 때
    func test_execute_throwsCreateFailed_whenRepositoryReturnsCreateFailed() async {
        // Given
        let useCase = DefaultCreateFolderUseCase(
            repository: MockFolderRepository(
                createBehavior: .createFailed
            )
        )

        // When & Then
        do {
            _ = try await useCase.execute(name: "New Folder")
            XCTFail("생성 실패의 경우 .createFailed 에러가 발생해야 합니다.")
        } catch UseCaseError.createFailed {
            // Success
        } catch {
            XCTFail("Expected .createFailed, got \(error)")
        }
    }

    /// 찾을 수 없는 경우 Case: Repository에서 .notFound를 반환할 때 .unknown으로 맵핑되는지 확인
    func test_execute_throwsUnknown_whenRepositoryReturnsNotFound() async {
        // Given
        let useCase = DefaultCreateFolderUseCase(
            repository: MockFolderRepository(
                createBehavior: .notFound
            )
        )

        // When & Then
        do {
            _ = try await useCase.execute(name: "Existing Folder")
            XCTFail("찾을 수 없을 시 .unknown으로 래핑되어야 합니다.")
        } catch UseCaseError.unknown(let error) {
            guard let repoError = error as? FolderRepositoryError else {
                return XCTFail("Unknown 에러 내부는 FolderRepositoryError가 적용되어야 합니다. ( Typed Throws )")
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
    }

    /// 수정 실패 Case: Repository에서 .updateFailed를 반환할 때 .unknown으로 맵핑되는지 확인
    func test_execute_throwsUnknown_whenRepositoryReturnsUpdateFailed() async {
        // Given
        let useCase = DefaultCreateFolderUseCase(
            repository: MockFolderRepository(
                createBehavior: .updateFailed
            )
        )

        // When & Then
        do {
            _ = try await useCase.execute(name: "Existing Folder")
            XCTFail("찾을 수 없을 시 .unknown으로 래핑되어야 합니다.")
        } catch UseCaseError.unknown(let error) {
            guard let repoError = error as? FolderRepositoryError else {
                return XCTFail("Unknown 에러 내부는 FolderRepositoryError가 적용되어야 합니다. ( Typed Throws )")
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
    }

    /// 조회 실패 Case: Repository에서 .fetchFailed를 반환할 때 .unknown으로 맵핑되는지 확인
    func test_execute_throwsUnknown_whenRepositoryReturnsFetchFailed() async {
        // Given
        let useCase = DefaultCreateFolderUseCase(
            repository: MockFolderRepository(
                createBehavior: .fetchFailed
            )
        )

        // When & Then
        do {
            _ = try await useCase.execute(name: "Existing Folder")
            XCTFail("찾을 수 없을 시 .unknown으로 래핑되어야 합니다.")
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
    }

    /// 알 수 없는 에러 Case: Repository에서 맵핑되지 않은 에러를 던질 때 .unknown으로 래핑되는지 확인
    func test_execute_throwsUnknown_whenRepositoryThrowsUnknown() async {
        // Given
        struct Dummy: Error {}
        let dummyError = Dummy()
        let useCase = DefaultCreateFolderUseCase(
            repository: MockFolderRepository(
                createBehavior: .unknown(dummyError)
            )
        )

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
    }
}

// MARK: - Error Cases ( Cancelled )

extension CreateFolderUseCaseTest {

    /// 작업 취소 Case: repository Cancelled의 경우 UseCase.Cancelled와 대칭 확인
    func test_execute_throwsCancelled_whenRepositoryReturnsCancelled() async {
        // Given
        let useCase = DefaultCreateFolderUseCase(
            repository: MockFolderRepository(
                createBehavior: .cancelled
            )
        )

        // When & Then
        do {
            _ = try await useCase.execute(name: "Existing Folder")
            XCTFail("작업 취소의 경우 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }

    /// 취소 Case: 작업이 즉시 취소된 경우 execute 함수 내부 isCancelled를 검증한다
    func test_execute_throwsCancelled_whenTaskIsCancelledPreemptively() async {
        // Given
        let useCase = DefaultCreateFolderUseCase(
            repository: MockFolderRepository(
                createBehavior: .success(Folder(path: URL.applicationSupportDirectory, name: "test"))
            )
        )

        // When & Then
        let task = Task { try await useCase.execute(name: "Cancel Test") }
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

    /// 취소 Case (During Execution): 작업 도중 Task가 취소된 경우
    func test_execute_throwsCancelled_whenTaskIsCancelledDuringExecution() async {
        // Given
        let useCase = DefaultCreateFolderUseCase(
            repository: MockFolderRepository(
                createBehavior: .success(Folder(path: URL(fileURLWithPath: "/"), name: "test")),
                delay: 100_000_000 // 0.1초 지연
            )
        )

        // When & Then
        let task = Task { try await useCase.execute(name: "Cancel Test") }

        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05초 대기 후 취소
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("작업 도중 취소되었으므로 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }

}
