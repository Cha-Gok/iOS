import XCTest
@testable import Domain

final class FetchBasicFolderUseCaseTest: XCTestCase {
    typealias UseCaseError = FetchBasicFolderUseCaseError
}

// MARK: - Success Cases

extension FetchBasicFolderUseCaseTest {

    func test_execute_기본폴더조회에성공하면_Folder를반환한다() async throws {
        // Given
        let expectedFolder = Folder(path: URL(fileURLWithPath: "/test"), name: "Basic Folder")
        let repository = MockWorkSpaceRepository()
        await repository.setBasicFolderResult(.success(expectedFolder))
        await repository.expectFetchOrCreateBasicFolder(callCount: 1)

        let useCase = DefaultFetchBasicFolderUseCase(repository: repository)

        // When
        let folder = try await useCase.execute()

        // Then
        XCTAssertEqual(folder.id, expectedFolder.id)
        XCTAssertEqual(folder.name, expectedFolder.name)
        await repository.verify()
    }
}

// MARK: - Error Cases

extension FetchBasicFolderUseCaseTest {

    func test_execute_기본폴더를찾을수없으면_notFound에러를던진다() async {
        // Given
        let repository = MockWorkSpaceRepository()
        await repository.setBasicFolderResult(.failure(.notFound))
        await repository.expectFetchOrCreateBasicFolder(callCount: 1)

        let useCase = DefaultFetchBasicFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("기본 폴더가 없는 경우 .notFound 에러가 발생해야 합니다.")
        } catch UseCaseError.notFound {
            // Success
            await repository.verify()
        } catch {
            XCTFail("Expected .notFound, got \(error)")
        }
    }

    func test_execute_기본폴더생성에실패하면_createFailed에러를던진다() async {
        // Given
        let repository = MockWorkSpaceRepository()
        await repository.setBasicFolderResult(.failure(.createFailed))
        await repository.expectFetchOrCreateBasicFolder(callCount: 1)

        let useCase = DefaultFetchBasicFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("생성 실패 시 .createFailed 에러가 발생해야 합니다.")
        } catch UseCaseError.createFailed {
            // Success
            await repository.verify()
        } catch {
            XCTFail("Expected .createFailed, got \(error)")
        }
    }

    func test_execute_기본폴더조회중알수없는에러가발생하면_unknown에러를던진다() async {
        // Given
        struct Dummy: Error {}
        let dummyError = Dummy()
        let repository = MockWorkSpaceRepository()
        await repository.setBasicFolderResult(.failure(.unknown(dummyError)))
        await repository.expectFetchOrCreateBasicFolder(callCount: 1)

        let useCase = DefaultFetchBasicFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("알 수 없는 에러 발생 시 .unknown으로 래핑되어야 합니다.")
        } catch UseCaseError.unknown(let error) {
            // RepoError.unknown 내부의 Dummy 에러가 유지되어야 함
            XCTAssertTrue(error is Dummy)
            await repository.verify()
        } catch {
            XCTFail("Expected .unknown, got \(error)")
        }
    }
}

// MARK: - Error Cases ( Cancelled )

extension FetchBasicFolderUseCaseTest {

    func test_execute_기본폴더조회중취소되면_cancelled에러를던진다() async {
        // Given
        let repository = MockWorkSpaceRepository()
        await repository.setBasicFolderResult(.failure(.cancelled))
        await repository.expectFetchOrCreateBasicFolder(callCount: 1)

        let useCase = DefaultFetchBasicFolderUseCase(repository: repository)

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("작업 취소의 경우 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
            await repository.verify()
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }

    func test_execute_기본폴더조회작업이취소되었으면_즉시cancelled에러를던진다() async {
        // Given
        let repository = MockWorkSpaceRepository()
        await repository.setBasicFolderResult(.success(Folder(path: URL(fileURLWithPath: "/"), name: "test")))
        await repository.expectFetchOrCreateBasicFolder(callCount: 0)

        let useCase = DefaultFetchBasicFolderUseCase(repository: repository)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await useCase.execute()
        }

        do {
            _ = try await task.value
            XCTFail("작업이 즉시 취소되었으므로 .cancelled 에러가 발생해야 합니다.")
        } catch UseCaseError.cancelled {
            // Success
            await repository.verify()
        } catch {
            XCTFail("Expected .cancelled, got \(error)")
        }
    }
}
