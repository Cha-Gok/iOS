@testable import Data
import Domain
import XCTest

final class DefaultWorkSpaceRepositoryTest: XCTestCase {}

// MARK: - fetchRootURL 테스트

extension DefaultWorkSpaceRepositoryTest {
    func test_정상적인파일시스템경로상태_루트URL조회시_ApplicationSupport경로를반환한다() async throws {
        let service = MockFileService()
        let sut = DefaultWorkSpaceRepository(fileService: service)

        // Given
        let baseURL = URL(fileURLWithPath: "/test/path")
        service.setUrlsResult(for: .applicationSupportDirectory, urls: [baseURL])
        service.expectUrls(callCount: 1)

        // When
        let result = try await sut.fetchRootURL()

        // Then
        let expectedURL = baseURL.appendingPathComponent("ChaGok", isDirectory: true)
        XCTAssertEqual(result, expectedURL)
        service.verify()
    }

    func test_파일시스템경로를찾을수없는상태_루트URL조회시_unknown에러를던진다() async throws {
        let service = MockFileService()
        let sut = DefaultWorkSpaceRepository(fileService: service)

        // Given
        service.setUrlsResult(for: .applicationSupportDirectory, urls: [])
        service.expectUrls(callCount: 1)

        // When & Then
        do {
            _ = try await sut.fetchRootURL()
            XCTFail("에러를 throw 해야 합니다.")
        } catch {
            guard case .unknown = error as? WorkSpaceRootURLRepositoryError else {
                return XCTFail("예상치 못한 에러: \(error)")
            }
        }
        service.verify()
    }

    func test_태스크취소상태_루트URL조회시_cancelled에러를던진다() async throws {
        let service = MockFileService()
        let sut = DefaultWorkSpaceRepository(fileService: service)

        // Given
        service.expectUrls(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.fetchRootURL()
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? WorkSpaceRootURLRepositoryError else {
                return XCTFail("예상치 못한 에러: \(error)")
            }
        }
        service.verify()
    }
}

// MARK: - fetchOrCreateBasicFolder 테스트

extension DefaultWorkSpaceRepositoryTest {
    func test_폴더가이미존재하는상태_기본폴더조회시_생성없이기존폴더모델을반환한다() async throws {
        let service = MockFileService()
        let sut = DefaultWorkSpaceRepository(fileService: service)

        // Given
        let baseURL = URL(fileURLWithPath: "/test/path")
        let rootURL = baseURL.appendingPathComponent("ChaGok", isDirectory: true)
        
        service.setUrlsResult(for: .applicationSupportDirectory, urls: [baseURL])
        service.setFileExistsResult(atPath: rootURL.path, exists: true)
        
        service.expectUrls(callCount: 1)
        service.expectFileExists(callCount: 1)
        service.expectCreateDirectory(callCount: 0)

        // When
        let folder = try await sut.fetchOrCreateBasicFolder()

        // Then
        XCTAssertEqual(folder.path, rootURL)
        XCTAssertEqual(folder.name, "ChaGok")
        service.verify()
    }

    func test_폴더가존재하지않는상태_기본폴더조회시_폴더를생성하고모델을반환한다() async throws {
        let service = MockFileService()
        let sut = DefaultWorkSpaceRepository(fileService: service)

        // Given
        let baseURL = URL(fileURLWithPath: "/test/path")
        let rootURL = baseURL.appendingPathComponent("ChaGok", isDirectory: true)
        
        service.setUrlsResult(for: .applicationSupportDirectory, urls: [baseURL])
        service.setFileExistsResult(atPath: rootURL.path, exists: false)
        
        service.expectUrls(callCount: 1)
        service.expectFileExists(callCount: 1)
        service.expectCreateDirectory(callCount: 1)

        // When
        let folder = try await sut.fetchOrCreateBasicFolder()

        // Then
        XCTAssertEqual(folder.path, rootURL)
        XCTAssertEqual(folder.name, "ChaGok")
        service.verify()
    }

    func test_폴더생성이실패하는상태_기본폴더조회시_createFailed에러를던진다() async throws {
        let service = MockFileService()
        let sut = DefaultWorkSpaceRepository(fileService: service)

        // Given
        let baseURL = URL(fileURLWithPath: "/test/path")
        let rootURL = baseURL.appendingPathComponent("ChaGok", isDirectory: true)
        
        service.setUrlsResult(for: .applicationSupportDirectory, urls: [baseURL])
        service.setFileExistsResult(atPath: rootURL.path, exists: false)
        service.setCreateDirectoryError(NSError(domain: "test", code: -1))
        
        service.expectCreateDirectory(callCount: 1)

        // When & Then
        do {
            _ = try await sut.fetchOrCreateBasicFolder()
            XCTFail("createFailed 에러를 throw 해야 합니다.")
        } catch {
            guard case .createFailed = error as? WorkSpaceBasicFolderRepositoryError else {
                return XCTFail("예상치 못한 에러: \(error)")
            }
        }
        service.verify()
    }

    func test_태스크취소상태_기본폴더조회시_cancelled에러를던진다() async throws {
        let service = MockFileService()
        let sut = DefaultWorkSpaceRepository(fileService: service)

        // Given
        service.expectUrls(callCount: 0)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.fetchOrCreateBasicFolder()
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? WorkSpaceBasicFolderRepositoryError else {
                return XCTFail("예상치 못한 에러: \(error)")
            }
        }
        service.verify()
    }
}
