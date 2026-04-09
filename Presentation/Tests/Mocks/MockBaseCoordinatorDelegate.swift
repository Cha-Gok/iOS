@testable import Presentation
import Foundation

@MainActor
final class MockBaseCoordinatorDelegate: BaseCoordinatorDelegate {
    var popCalled = false

    func pop() {
        popCalled = true
    }
}
