import Core
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    private(set) var dependencyContainer: AppDIContainer?
    private(set) var initializationError: Error?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        configureNavigationBarAppearance()
        do {
            #if DEBUG
                AppLogger.info("진짜 폴더 위치: \(NSHomeDirectory())")
            #endif
            dependencyContainer = try AppDIContainer()
        } catch {
            AppLogger.error(error)
            initializationError = error
        }
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        dependencyContainer?.voiceNoteAnalysisService.cancelAll()
    }

    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        appearance.shadowColor = .clear

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
        config.delegateClass = SceneDelegate.self
        return config
    }
}
