@testable import Data
import Foundation
import XCTest

final class MockFileService: FileService, @unchecked Sendable {
    private var urlsResults: [FileManager.SearchPathDirectory: [URL]] = [:]
    private var fileExistsResults: [String: Bool] = [:]
    private var createDirectoryError: Error?

    private(set) var urlsCallCount = 0
    private(set) var fileExistsCallCount = 0
    private(set) var createDirectoryCallCount = 0

    private var expectedUrlsCallCount: Int?
    private var expectedFileExistsCallCount: Int?
    private var expectedCreateDirectoryCallCount: Int?

    func setUrlsResult(for directory: FileManager.SearchPathDirectory, urls: [URL]) {
        urlsResults[directory] = urls
    }

    func setFileExistsResult(atPath path: String, exists: Bool) {
        fileExistsResults[path] = exists
    }

    func setCreateDirectoryError(_ error: Error) {
        createDirectoryError = error
    }

    func expectUrls(callCount: Int) {
        expectedUrlsCallCount = callCount
    }

    func expectFileExists(callCount: Int) {
        expectedFileExistsCallCount = callCount
    }

    func expectCreateDirectory(callCount: Int) {
        expectedCreateDirectoryCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedUrlsCallCount {
            XCTAssertEqual(
                urlsCallCount,
                expected,
                "urls(for:in:) 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expected = expectedFileExistsCallCount {
            XCTAssertEqual(
                fileExistsCallCount,
                expected,
                "fileExists(atPath:) 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expected = expectedCreateDirectoryCallCount {
            XCTAssertEqual(
                createDirectoryCallCount,
                expected,
                "createDirectory(at:withIntermediateDirectories:attributes:) 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
    }

    func urls(
        for directory: FileManager.SearchPathDirectory,
        in domainMask: FileManager.SearchPathDomainMask
    ) -> [URL] {
        urlsCallCount += 1
        return urlsResults[directory] ?? []
    }

    func fileExists(atPath path: String) -> Bool {
        fileExistsCallCount += 1
        return fileExistsResults[path] ?? false
    }

    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws {
        createDirectoryCallCount += 1
        if let error = createDirectoryError {
            throw error
        }
    }
}
