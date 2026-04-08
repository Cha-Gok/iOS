import Domain
import Presentation
import UIKit

@MainActor
final class MainCoordinator: BaseCoordinator<UINavigationController> {
    private let dependencyContainer: AppDIContainer

    init(
        presenter: UINavigationController,
        dependencyContainer: AppDIContainer
    ) {
        self.dependencyContainer = dependencyContainer
        super.init(presenter: presenter)
    }

    override func start() {
        let mainVM = dependencyContainer.makeMainViewModel()
        let mainVC = MainViewController(vm: mainVM)
        mainVM.mainCoordinator = self
        presenter.isNavigationBarHidden = false
        presenter.setViewControllers([mainVC], animated: false)
    }
}

// MARK: - RecordingCoordinating

extension MainCoordinator: RecordingCoordinating {
    func cancelRecording() {
        presenter.dismiss(animated: true)
    }

    func finishRecording(voiceRecord: VoiceRecord) {
        presenter.dismiss(animated: true)
    }
}

// MARK: - MainViewCoordinator

extension MainCoordinator: MainViewCoordinatorDelegate {
    // TODO: Push

    func pushTrashView() {
        let trashView = dependencyContainer.makeTrashViewController()
        presenter.pushViewController(trashView, animated: true)
    }

    func pushMyFolderView(category: CategoryToggle) {
        let myFolderVM = dependencyContainer.makeMyFolderViewModel(category)
        myFolderVM.coordinator = self
        let myFolderVC = FolderViewController(vm: myFolderVM)
        presenter.pushViewController(myFolderVC, animated: true)
    }

    // TODO: Present

    func presentRecodingView() {
        let navController = UINavigationController()
        let viewModel = dependencyContainer.makeRecordingViewModel()
        viewModel.coordinator = self
        let recordingVC = RecordingViewController(viewModel: viewModel)
        navController.modalPresentationStyle = .fullScreen
        navController.setViewControllers([recordingVC], animated: false)
        presenter.present(navController, animated: true)
    }

    // TODO: Pop

    func popMyFolderView() {
        presenter.popViewController(animated: true)
    }
}
