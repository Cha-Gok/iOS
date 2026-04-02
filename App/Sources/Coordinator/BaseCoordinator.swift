import UIKit

@MainActor
class BaseCoordinator<ControllerType: UIViewController>: Identifiable {
    let id: UUID
    private(set) var childCoordinators: [UUID: Any] = [:]
    let presenter: ControllerType

    init(id: UUID = UUID(), presenter: ControllerType) {
        self.id = id
        self.presenter = presenter
    }

    func start() {
        preconditionFailure("Not implemented")
    }
}

extension BaseCoordinator {
    func store(coordinator: BaseCoordinator<some UIViewController>) {
        let existCoordinator = childCoordinators.contains(where: { key, value -> Bool in
            key == coordinator.id
        })

        if !existCoordinator {
            childCoordinators[coordinator.id] = coordinator
        }
    }

    func free(coordinator: BaseCoordinator<some UIViewController>) {
        let existCoordinator = childCoordinators.contains(where: { key, value -> Bool in
            key == coordinator.id
        })

        if existCoordinator {
            childCoordinators[coordinator.id] = nil
        }
    }

    func clearChildCoordinator() {
        childCoordinators = [:]
    }

    func childCoordinator<T>(forKey key: UUID) -> T? {
        return childCoordinators.first(where: { $0.key == key })?.value as? T
    }
}
