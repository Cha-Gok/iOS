@testable import Data
import Foundation
import XCTest

final class FileManagerStorageServiceTests: XCTestCase {
    /// 테스트용 디렉토리 이름을 생성하고 클린업을 위한 URL을 반환합니다.
    private func makeTestDirectory() -> (name: String, url: URL) {
        let name = "Test_ChaGok_\(UUID().uuidString)"
        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentURL.appendingPathComponent(name)
        return (name, url)
    }

    private func cleanUp(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - 통합 테스트

extension FileManagerStorageServiceTests {
    func test_유효한데이터일때_저장및로드요청시_성공한다() throws {
        let sut = FileManagerStorageService()
        let (dirName, dirURL) = makeTestDirectory()
        defer { cleanUp(dirURL) }

        // Given
        let data = "Hello, ChaGok!".data(using: .utf8)!
        let fileName = "test_roundtrip.txt"

        // When
        let relativePath = try sut.save(data: data, toDirectory: dirName, fileName: fileName)
        let loadedData = try sut.load(relativePath: relativePath)
        let isExists = sut.exists(relativePath: relativePath)

        // Then
        XCTAssertTrue(isExists)
        XCTAssertEqual(data, loadedData)
    }

    func test_파일이존재할때_삭제요청시_성공적으로삭제한다() throws {
        let sut = FileManagerStorageService()
        let (dirName, dirURL) = makeTestDirectory()
        defer { cleanUp(dirURL) }

        // Given
        let data = Data([0x01])
        let relativePath = try sut.save(data: data, toDirectory: dirName, fileName: "delete.me")
        let absoluteURL = sut.absoluteURL(for: relativePath)

        // When
        try sut.delete(fileURL: absoluteURL)
        let isExists = sut.exists(relativePath: relativePath)

        // Then
        XCTAssertFalse(isExists)
    }
}

// MARK: - 에러 매핑 테스트

extension FileManagerStorageServiceTests {
    func test_존재하지않는파일일때_로드요청시_fileNotFound에러를던진다() throws {
        let sut = FileManagerStorageService()
        let nonExistentPath = "NonExistent/\(UUID().uuidString).txt"

        // When & Then
        do {
            _ = try sut.load(relativePath: nonExistentPath)
            XCTFail("StorageServiceError.fileNotFound 에러를 throw 해야 합니다.")
        } catch {
            guard case StorageServiceError.fileNotFound = error else {
                return XCTFail("예상한 에러는 .fileNotFound 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
    }

    func test_존재하지않는파일일때_삭제요청시_fileNotFound에러를던진다() throws {
        let sut = FileManagerStorageService()
        let nonExistentURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        // When & Then
        do {
            try sut.delete(fileURL: nonExistentURL)
            XCTFail("StorageServiceError.fileNotFound 에러를 throw 해야 합니다.")
        } catch {
            guard case StorageServiceError.fileNotFound = error else {
                return XCTFail("예상한 에러는 .fileNotFound 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
    }
}

// MARK: - 작업 취소 테스트

extension FileManagerStorageServiceTests {
    func test_태스크취소상태일때_저장요청시_cancelled에러를던진다() async throws {
        let sut = FileManagerStorageService()

        // Given
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try sut.save(data: Data(), toDirectory: "any", fileName: "any")
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("StorageServiceError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case StorageServiceError.cancelled = error else {
                return XCTFail("예상한 에러는 .cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
    }

    func test_태스크취소상태일때_이동요청시_cancelled에러를던진다() async throws {
        let sut = FileManagerStorageService()

        // Given
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try sut.moveFile(from: URL(fileURLWithPath: "/"), toDirectory: "any", fileName: "any")
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("StorageServiceError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case StorageServiceError.cancelled = error else {
                return XCTFail("예상한 에러는 .cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
    }
}

// MARK: - 파일 이동 및 엣지 케이스 테스트

extension FileManagerStorageServiceTests {
    func test_임시파일이있을때_이동요청시_목적지로성공적으로이동한다() throws {
        let sut = FileManagerStorageService()
        let (dirName, dirURL) = makeTestDirectory()
        defer { cleanUp(dirURL) }

        // Given
        let fileName = "move.txt"
        let tempURL = try sut.generateTemporaryURL(fileName: fileName)
        let data = "Move Me".data(using: .utf8)!
        try data.write(to: tempURL)

        // When
        let relativePath = try sut.moveFile(from: tempURL, toDirectory: dirName, fileName: fileName)
        let isFinalExists = sut.exists(relativePath: relativePath)
        let isTempExists = sut.exists(relativePath: tempURL.path)

        // Then
        XCTAssertTrue(isFinalExists)
        XCTAssertFalse(isTempExists)
    }

    func test_목적지에파일이미있을때_이동요청시_덮어쓰기에성공한다() throws {
        let sut = FileManagerStorageService()
        let (dirName, dirURL) = makeTestDirectory()
        defer { cleanUp(dirURL) }

        // Given
        let fileName = "overwrite.txt"
        let oldData = try XCTUnwrap("Old".data(using: .utf8))
        _ = try sut.save(data: oldData, toDirectory: dirName, fileName: fileName)

        let tempURL = try sut.generateTemporaryURL(fileName: fileName)
        let newData = "New".data(using: .utf8)!
        try newData.write(to: tempURL)

        // When
        let relativePath = try sut.moveFile(from: tempURL, toDirectory: dirName, fileName: fileName)
        let loadedData = try sut.load(relativePath: relativePath)

        // Then
        XCTAssertEqual(loadedData, newData)
    }

    func test_디렉토리가없을때_저장요청시_자동으로디렉토리를생성한다() throws {
        let sut = FileManagerStorageService()
        let (dirName, dirURL) = makeTestDirectory()
        defer { cleanUp(dirURL) }

        // Given
        let nestedDir = "\(dirName)/nested/deep"
        let data = Data([0x01])

        // When
        let relativePath = try sut.save(data: data, toDirectory: nestedDir, fileName: "test.data")
        let isExists = sut.exists(relativePath: relativePath)

        // Then
        XCTAssertTrue(isExists)
    }
}
