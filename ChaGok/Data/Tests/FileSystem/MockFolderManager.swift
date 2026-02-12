import Foundation
@testable import Data

final class MockFolderManager: FolderSystemInternalDataSource {
    var rootDirectory: URL = URL(filePath: "/mock")
    static let rootName: String = "MockRoot"
    var directoryExistResult: Bool = true
    var didCallCreateDirectory: Bool = false

    func createRootDirectoryIfNeeded(url: URL) {
        didCallCreateDirectory = true
    }

    func directoryExists(url: URL) -> Bool {
        directoryExistResult
    }
}
