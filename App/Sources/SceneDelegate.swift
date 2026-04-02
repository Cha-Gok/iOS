import Data
import Domain
import Presentation
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    /// DI 컨테이너를 공유 인스턴스로 사용합니다.
    private let appDIContainer = AppDIContainer.shared

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // DI Container를 통해 첫 실행 여부를 확인하고 진입 화면을 분기합니다.
        let checkFirstLaunchUseCase = appDIContainer.makeCheckFirstLaunchUseCase()
        let isFirstLaunch: Bool = checkFirstLaunchUseCase.checkIsFirstLaunch()

        if isFirstLaunch {
            window.rootViewController = appDIContainer.makeOnBoardingViewController(onFinish: { [
                weak window
            ] in
                // 온보딩 완료 시 메인 뷰로 모드 전환
                guard let window else { return }
                window.rootViewController = AppDIContainer.shared.makeMainViewController()

                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
            })
        } else {
            window.rootViewController = appDIContainer.makeMainViewController()
        }

        window.makeKeyAndVisible()
    }
}
