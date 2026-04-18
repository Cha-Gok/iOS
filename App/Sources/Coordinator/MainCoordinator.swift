import Core
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

    func finishRecording(voiceNote: VoiceNote) {
        presenter.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            let voiceNoteVM = dependencyContainer.makeVoiceNoteViewModel(voiceNote: voiceNote)
            voiceNoteVM.coordinator = self
            let voiceNoteVC = VoiceNoteViewController(viewModel: voiceNoteVM)
            presenter.pushViewController(voiceNoteVC, animated: true)
        }
    }
}

// MARK: - MainViewCoordinator

extension MainCoordinator: MainCoordinatorDelegate {
    // TODO: Push

    func pushTrashView() {
        let trashVM = dependencyContainer.makeTrashViewModel()
        trashVM.coordinator = self
        let trashVC = TrashViewController(vm: trashVM)
        presenter.pushViewController(trashVC, animated: true)
    }

    func pushMyFolderView(category: CategoryToggle) {
        let myFolderVM = dependencyContainer.makeMyFolderViewModel(category)
        myFolderVM.coordinator = self
        let myFolderVC = FolderViewController(vm: myFolderVM)
        presenter.pushViewController(myFolderVC, animated: true)
    }

    func pushVoiceNoteView(voiceNote: VoiceNote) {
        let voiceNoteVM = dependencyContainer.makeVoiceNoteViewModel(voiceNote: voiceNote)
        voiceNoteVM.coordinator = self
        let voiceNoteVC = VoiceNoteViewController(viewModel: voiceNoteVM)
        presenter.pushViewController(voiceNoteVC, animated: true)
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
}

// MARK: FolderCoordinating

extension MainCoordinator: FolderCoordinatorDelegate {
    func pushMyFolderDetailView(_ folder: Folder) {
        let myFolderDetailVM = dependencyContainer.makeMyFolderDetailViewModel(folder)
        myFolderDetailVM.coordinator = self
        let myFolderDetailVC = FolderDetailViewController(vm: myFolderDetailVM)
        presenter.pushViewController(myFolderDetailVC, animated: true)
    }
}

// MARK: DetailFolderCoordinating

extension MainCoordinator: FolderDetailCoordinatorDelegate {}

// MARK: VoiceNoteCoordinating

extension MainCoordinator: VoiceNoteCoordinatorDelegate {}

// MARK: - NewFolderCoordinatorDelegate

extension MainCoordinator: NewFolderCoordinatorDelegate {
    func cancel() {
        guard let nav = presenter.presentedViewController as? UINavigationController,
              let sheet = nav.sheetPresentationController else { return }

        nav.popViewController(animated: true)

        sheet.animateChanges {
            sheet.detents = [.medium()]
        }
    }

    func folderCreated() {
        guard let nav = presenter.presentedViewController as? UINavigationController,
              let sheet = nav.sheetPresentationController else { return }

        nav.popViewController(animated: true)

        sheet.animateChanges {
            sheet.detents = [.medium()]
        }
    }
}

// MARK: - MoveFolderListCoordinatorDelegate

extension MainCoordinator: MoveFolderListCoordinatorDelegate {
    func dismiss() {
        presenter.dismiss(animated: true)
    }

    func pushNewFolder() {
        guard let nav = presenter.presentedViewController as? UINavigationController,
              let sheet = nav.sheetPresentationController else { return }

        let viewModel = dependencyContainer.makeNewFolderViewModel()
        viewModel.coordinator = self
        let newFolderVC = NewFolderViewController(viewModel: viewModel)
        newFolderVC.view.layoutIfNeeded()

        nav.pushViewController(newFolderVC, animated: true)

        sheet.animateChanges {
            sheet.detents = [.custom { [weak newFolderVC] _ in
                newFolderVC?.preferredContentSize.height
            }]
        }
    }
}

// MARK: Base 공통 함수 묶음

extension MainCoordinator: BaseCoordinatorDelegate {
    // TODO: Pop

    func pop() {
        presenter.popViewController(animated: true)
    }
    
    // TODO: Present 폴더 이동 시트 ( 사용 화면 - 음성 노트, 개인 폴더 )
    func presentFolderList(with receive: Receive, dismiss: (() -> Void)?) {
        let viewModel = dependencyContainer.makeMoveFolderListViewModel(receive: receive, dismiss: dismiss)
        viewModel.coordinator = self
        let viewController = MoveFolderListViewController(viewModel: viewModel)
        let nav = UINavigationController(rootViewController: viewController)
        nav.isNavigationBarHidden = true

        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }

        presenter.present(nav, animated: true)
    }
}
