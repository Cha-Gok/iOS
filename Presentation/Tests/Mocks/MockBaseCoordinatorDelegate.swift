@testable import Presentation
import Foundation

@MainActor
final class MockBaseCoordinatorDelegate: BaseCoordinatorDelegate {
    var popCalled = false
    var presentFolderListCalled = false
    
    func presentFolderList(with: Presentation.Receive, dismiss: (() -> Void)?) {
        presentFolderListCalled = true
    }

    func pop() {
        popCalled = true
    }
}
