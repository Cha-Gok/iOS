@testable import Domain
import Core
import XCTest

final class FetchBasicFolderUseCaseTest: XCTestCase {
    private var repository: MockWorkSpaceRepository!
    private var sut: DefaultFetchBasicFolderUseCase!

    override func setUp() {
        super.setUp()
        repository = MockWorkSpaceRepository()
        sut = DefaultFetchBasicFolderUseCase(repository: repository)
    }

    override func tearDown() {
        repository = nil
        sut = nil
        super.tearDown()
    }
}

// MARK: - 성공 케이스

extension FetchBasicFolderUseCaseTest {
    func test_정상상태_기본폴더조회시_기대하는Folder를반환한다() async throws {
        // Given
        let expectedFolder = Folder(name: "Basic Folder")
        await repository.setBasicFolderResult(.success(expectedFolder))
        await repository.expectFetchOrCreateBasicFolder(callCount: 1)

        // When
        let folder = try await sut.execute()

        // Then
        XCTAssertEqual(folder.id, expectedFolder.id)
        XCTAssertEqual(folder.name, expectedFolder.name)
        await repository.verify()
    }
}

// MARK: - 에러 케이스

extension FetchBasicFolderUseCaseTest {
    func test_기본폴더미존재상태_기본폴더조회시_notFound에러를던진다() async {
        // Given
        await repository.setBasicFolderResult(.failure(.notFound))
        await repository.expectFetchOrCreateBasicFolder(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("FetchBasicFolderUseCaseError.notFound 에러를 throw 해야 합니다.")
        } catch {
            guard case .notFound = error else {
                return XCTFail(
                    "예상한 에러는 FetchBasicFolderUseCaseError.notFound 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
        await repository.verify()
    }

    func test_폴더생성실패상태_기본폴더조회시_createFailed에러를던진다() async {
        // Given
        await repository.setBasicFolderResult(.failure(.createFailed))
        await repository.expectFetchOrCreateBasicFolder(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("FetchBasicFolderUseCaseError.createFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .createFailed = error else {
                return XCTFail(
                    "예상한 에러는 FetchBasicFolderUseCaseError.createFailed 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
        await repository.verify()
    }

    func test_알수없는에러발생상태_기본폴더조회시_unknown에러를던진다() async {
        // Given
        struct DummyError: Error {}
        let dummyError = DummyError()
        await repository.setBasicFolderResult(.failure(.unknown(dummyError)))
        await repository.expectFetchOrCreateBasicFolder(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("FetchBasicFolderUseCaseError.unknown 에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown(let repoError) = error else {
                return XCTFail(
                    "예상한 에러는 FetchBasicFolderUseCaseError.unknown 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
            XCTAssertTrue(repoError is DummyError)
        }
        await repository.verify()
    }

    func test_조회중취소상태_기본폴더조회시_cancelled에러를던진다() async {
        // Given
        await repository.setBasicFolderResult(.failure(.cancelled))
        await repository.expectFetchOrCreateBasicFolder(callCount: 1)

        // When & Then
        do {
            _ = try await sut.execute()
            XCTFail("FetchBasicFolderUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error else {
                return XCTFail(
                    "예상한 에러는 FetchBasicFolderUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
        await repository.verify()
    }

    func test_태스크이미취소상태_기본폴더조회시_즉시cancelled에러를던진다() async {
        guard let sut else {
            return XCTFail("sut가 초기화되지 않았습니다.")
        }
        // Given
        await repository.setBasicFolderResult(
            .success(Folder(name: "test"))
        )
        await repository.expectFetchOrCreateBasicFolder(callCount: 0)

        // When & Then
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.execute()
        }

        do {
            _ = try await task.value
            XCTFail("FetchBasicFolderUseCaseError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? FetchBasicFolderUseCaseError else {
                return XCTFail(
                    "예상한 에러는 FetchBasicFolderUseCaseError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다."
                )
            }
        }
        await repository.verify()
    }
}
