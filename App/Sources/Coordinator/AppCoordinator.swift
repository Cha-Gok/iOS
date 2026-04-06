import Domain
import Presentation
import UIKit

@MainActor
final class AppCoordinator: BaseCoordinator<UINavigationController> {
    let window: UIWindow
    let dependencyContainer: AppDIContainer = .init()

    init(window: UIWindow) {
        self.window = window
        let presenter = UINavigationController()
        presenter.isToolbarHidden = true
        presenter.isNavigationBarHidden = true

        super.init(presenter: presenter)
        self.window.rootViewController = presenter
        self.window.makeKeyAndVisible()
    }

    override func start() {
        let firstUser: Bool = dependencyContainer.checkFirstLaunchUser()
        if firstUser {
            startOnBoarding()
        } else {
            startMain()
        }
    }

    private func startOnBoarding() {
        let onBoardingVC = dependencyContainer.makeOnBoardingViewController()
        onBoardingVC.vm.navDelegate = self
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
        let recordingVC = dependencyContainer.makeRecordingViewController(coordinator: self)
        let nav = UINavigationController(rootViewController: recordingVC)
        nav.modalPresentationStyle = .fullScreen
        presenter.present(nav, animated: true)
    }
}

// MARK: - Navigation Delegate

extension AppCoordinator: RecordingCoordinating {
    func cancelRecording() {
        presenter.dismiss(animated: true)
    }

    func finishRecording(voiceRecord: VoiceRecord) {
        presenter.dismiss(animated: true)
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
