import Presentation
import UIKit

@MainActor
final class AppCoordinator: BaseCoordinator<UINavigationController> {
    let window: UIWindow
    let dependencyContainer: AppDIContainer

    init(window: UIWindow, dependencyContainer: AppDIContainer) {
        self.window = window
        self.dependencyContainer = dependencyContainer
        let presenter = UINavigationController()
        presenter.isToolbarHidden = true
        presenter.isNavigationBarHidden = true

        super.init(presenter: presenter)
        self.window.rootViewController = presenter
        self.window.makeKeyAndVisible()
    }

    override func start() {
        let checkFirstLaunchRepository = dependencyContainer.makeCheckFirstLaunchRepository()
        if checkFirstLaunchRepository.checkIsFirstLaunch() {
            startOnboarding()
        } else {
            startMain()
        }
    }

    private func startOnboarding() {
        let viewModel = dependencyContainer.makeOnBoardingViewModel()
        viewModel.onBoardingCoordinator = self
        let onBoardingVC = OnBoardingViewController(vm: viewModel)
        presenter.setViewControllers([onBoardingVC], animated: false)
    }

    func showMain() {
        clearChildCoordinator()
        startMain()

        UIView.transition(
            with: window,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: nil,
            completion: nil
        )
    }

    private func startMain() {
        #if DEBUG
            dependencyContainer.seedDebugDataIfNeeded()
        #endif
        let coordinator = MainCoordinator(
            presenter: presenter,
            dependencyContainer: dependencyContainer
        )
        store(coordinator: coordinator)
        coordinator.start()
    }
}

// MARK: - OnboardingCoordinatorDelegate

extension AppCoordinator: OnboardingCoordinatorDelegate {
    func finishOnBoarding() {
        showMain()
    }
}
