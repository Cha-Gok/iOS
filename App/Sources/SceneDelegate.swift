import Core
import Data
import Domain
import Presentation
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private var appCoordinator: AppCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let appDelegate = UIApplication.shared.delegate as? AppDelegate

        if let dependencyContainer = appDelegate?.dependencyContainer {
            appCoordinator = .init(
                window: window,
                dependencyContainer: dependencyContainer
            )
            appCoordinator?.start()
        } else {
            let error = appDelegate?.initializationError
                ?? NSError(domain: "ChaGok", code: -1, userInfo: nil)
            showInitializationFailureAlert(on: window, error: error)
        }
    }
}

private extension SceneDelegate {
    func showInitializationFailureAlert(on window: UIWindow, error: Error) {
        let rootViewController = UIViewController()
        rootViewController.view.backgroundColor = .systemBackground
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()

        let message = (error as? LocalizedError)?.errorDescription ?? "알 수 없는 오류가 발생했습니다."
        let alertController = UIAlertController(
            title: "앱 초기화 실패",
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "확인", style: .default))

        rootViewController.present(alertController, animated: true)
    }
}
