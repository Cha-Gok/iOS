import Foundation
@testable import Data

final class MockFolderManager: FolderSystem {
    var rootDirectory: URL = URL(filePath: "/mock")
    static let rootName: String = "MockRoot"
    var directoryExistResult: Bool = true
    var didCallCreateDirectory: Bool = false
    // FUNCTION
    func createRootDirectoryIfNeeded(url: URL) {
        didCallCreateDirectory = true
    }
    func directoryExists(url: URL) -> Bool {
        directoryExistResult
    }
}
