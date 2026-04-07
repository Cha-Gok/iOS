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
        let checkFirstLaunchUseCase = dependencyContainer.makeCheckFirstLaunchUseCase()
        let isFirstLaunch = checkFirstLaunchUseCase.checkIsFirstLaunch()
        isFirstLaunch ? startOnBoarding() : startMain()
    }

    private func startOnBoarding() {
        let onBoardingViewModel = dependencyContainer.makeOnBoardingViewModel()
        onBoardingViewModel.navDelegate = self
        let onBoardingVC = OnBoardingViewController(vm: onBoardingViewModel)
        presenter.setViewControllers([onBoardingVC], animated: false)
    }

    private func startMain() {
        let mainVC = dependencyContainer.makeMainViewController()
        mainVC.onRecordingButtonTapped = { [weak self] in
            self?.presentRecording()
        }
        presenter.setViewControllers([mainVC], animated: false)
    }

    private func presentRecording() {
        let coordinator = RecordingCoordinator(
            dependencyContainer: dependencyContainer,
            parentCoordinator: self
        )
        store(coordinator: coordinator)
        coordinator.start()
        presenter.present(coordinator.presenter, animated: true)
    }
}

extension AppCoordinator: OnboardingCoordinatorDelegate {
    /// 온보딩 화면에서 메인 화면으로 넘어가는 Navigation 함수
    func finishOnBoarding() {
        startMain()

        UIView.transition(
            with: window,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: nil,
            completion: nil
        )
    }
}
