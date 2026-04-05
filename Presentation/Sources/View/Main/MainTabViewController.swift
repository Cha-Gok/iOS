import UIKit

public final class MainTabViewController: UITabBarController {
    private lazy var recordVC = RecordingViewController()
    private lazy var mainVC = MainViewController()
    private lazy var folderVC = FolderViewController()

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
    }

    private func setupTabBar() {
        recordVC.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(systemName: "microphone"),
            selectedImage: UIImage(systemName: "microphone.fill")
        )
        mainVC.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        folderVC.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(systemName: "folder"),
            selectedImage: UIImage(systemName: "folder.fill")
        )

        // viewControllers 연결
        viewControllers = [recordVC, mainVC, folderVC]

        // 초기 시작 TabBar 선택
        selectedIndex = 1
    }
}
