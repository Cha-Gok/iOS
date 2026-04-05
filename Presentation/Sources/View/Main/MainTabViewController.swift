import UIKit

public final class MainTabViewController: UITabBarController {
    private let recordVC: RecordingViewController
    private let mainVC: MainViewController
    private let folderVC: FolderViewController

    public init(
        recordVC: RecordingViewController,
        mainVC: MainViewController,
        folderVC: FolderViewController
    ) {
        self.recordVC = recordVC
        self.mainVC = mainVC
        self.folderVC = folderVC
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
