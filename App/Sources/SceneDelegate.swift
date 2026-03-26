import Data
import Domain
import Presentation
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private var dependency: SandboxDependency?

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        window.makeKeyAndVisible()

        Task {
            let provider: DependencyProvider = .init()
            guard let dependency: SandboxDependency = await provider.getDependency() else {
                fatalError("dependency가 생성이 되지 않았습니다!!")
            }
            window.rootViewController = SandBoxTestViewController(
                dependency: dependency
            )
        }
    }
}
