import Foundation

@MainActor
public protocol BaseCoordinatorDelegate: AnyObject {
    func pop()
}
