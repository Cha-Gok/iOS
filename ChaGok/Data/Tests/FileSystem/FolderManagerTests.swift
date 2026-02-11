import XCTest
@testable import Data

final class FolderManagerTests: XCTestCase {
    /// FolderManager 초기화 시 Root 디렉토리가 생성되는지 검증한다.
    /// FolderManager가 생성되면 Root 디렉토리는 반드시 존재 해야 한다.
    /// WorkFlow --> UUID() 폴더 생성 -> UUID() 폴더 삭제
    func testInitializeFolderExists() throws {
        let baseURL: URL = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString, isDirectory: true
        )
        defer {
            try? FileManager.default.removeItem(at: baseURL)
        }
        let manager: FolderManager = .init(fileManager: .default, baseURL: baseURL)
        let matchedURL: URL = baseURL.appending(
            path: type(of: manager).rootName,
            directoryHint: .isDirectory
        )
        XCTAssertEqual(manager.rootDirectory, matchedURL)
        let exists: Bool = manager.directoryExists(url: manager.rootDirectory)
        XCTAssertTrue(exists, "루트 디렉토리가 초기화 후 존재 합니다.")
    }
    /// createRootDirectoryIfNeeded 호출 시
    /// 디렉토리 생성 로직이 실행되는지(Mock 기반) 검증한다.
    func testFolderLogicInspection() {
        let mock: MockFolderManager = .init()
        mock.createRootDirectoryIfNeeded(url: URL.applicationSupportDirectory)
        XCTAssertTrue(mock.didCallCreateDirectory) // 폴더가 생성
        XCTAssertTrue(mock.directoryExistResult)   // 폴더 존재 유무
    }
}
