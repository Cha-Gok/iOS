import Core
import Domain
import Presentation
import SwiftUI
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
        mainVM.alertCoordinator = self
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
        trashVM.alertCoordinator = self
        let trashVC = TrashViewController(vm: trashVM)
        presenter.pushViewController(trashVC, animated: true)
    }

    func pushMyFolderView(category: CategoryToggle) {
        let myFolderVM = dependencyContainer.makeMyFolderViewModel(category)
        myFolderVM.coordinator = self
        myFolderVM.alertCoordinator = self
        let myFolderVC = FolderViewController(vm: myFolderVM)
        presenter.pushViewController(myFolderVC, animated: true)
    }

    func pushVoiceNoteView(voiceNote: VoiceNote) {
        let voiceNoteVM = dependencyContainer.makeVoiceNoteViewModel(voiceNote: voiceNote)
        voiceNoteVM.coordinator = self
        let voiceNoteVC = VoiceNoteViewController(viewModel: voiceNoteVM)
        presenter.pushViewController(voiceNoteVC, animated: true)
    }

    func pushSearchView(type: SearchViewModel.SearchType, items: [ContentItem]) {
        let searchVM = dependencyContainer.makeSearchViewModel(type: type, items: items)
        searchVM.coordinator = self
        let searchVC = SearchViewController(vm: searchVM)

        presenter.pushViewController(searchVC, animated: true)
    }

    // TODO: Present

    func presentRecodingView() {
        let navController = UINavigationController()
        let isModelDownloaded = dependencyContainer.isWhisperModelDownloaded()

        if isModelDownloaded {
            let viewModel = dependencyContainer.makeRecordingViewModel()
            viewModel.coordinator = self
            viewModel.alertCoordinator = self
            let recordingVC = RecordingViewController(viewModel: viewModel)
            navController.isNavigationBarHidden = false
            navController.modalPresentationStyle = .fullScreen
            navController.setViewControllers([recordingVC], animated: false)
        } else {
            let viewModel = dependencyContainer.makeDownloadOnDeviceViewModel()
            viewModel.coordinator = self
            let downloadVC = DownloadOnDeviceViewController(vm: viewModel)
            navController.isNavigationBarHidden = true
            navController.modalPresentationStyle = .pageSheet
            navController.setViewControllers([downloadVC], animated: false)

            if let sheet = navController.sheetPresentationController {
                sheet.detents = [.medium()]
                sheet.prefersGrabberVisible = true
            }
        }

        presenter.present(navController, animated: true)
    }
}

// MARK: - FolderCoordinatorDelegate

extension MainCoordinator: FolderCoordinatorDelegate {
    func pop() {
        presenter.popViewController(animated: true)
    }

    func pushMyFolderDetailView(_ folder: Folder) {
        let myFolderDetailVM = dependencyContainer.makeMyFolderDetailViewModel(folder)
        myFolderDetailVM.coordinator = self
        myFolderDetailVM.alertCoordinator = self
        let myFolderDetailVC = FolderDetailViewController(vm: myFolderDetailVM)
        presenter.pushViewController(myFolderDetailVC, animated: true)
    }
}

// MARK: - FolderDetailCoordinatorDelegate

extension MainCoordinator: FolderDetailCoordinatorDelegate {
    func presentFolderList(with voiceNotes: [VoiceNote], onComplete: ((String) -> Void)?) {
        presentMoveFolder(voiceNotes: voiceNotes, onComplete: onComplete, topDetentStyle: .belowNavigationBar)
    }
}

// MARK: - TrashCoordinatorDelegate

extension MainCoordinator: TrashCoordinatorDelegate {
    func pushMyFolderDetailView(_ folder: Folder, isHidden: Bool) {
        let myFolderDetailVM = dependencyContainer.makeMyFolderDetailViewModel(folder, isTrashMode: isHidden)
        myFolderDetailVM.coordinator = self
        myFolderDetailVM.alertCoordinator = self
        let myFolderDetailVC = FolderDetailViewController(vm: myFolderDetailVM)
        presenter.pushViewController(myFolderDetailVC, animated: true)
    }

    func pushSearchView(
        type: Presentation.SearchViewModel.SearchType,
        items: [ContentItem],
        isHidden: Bool
    ) {
        let searchVM = dependencyContainer.makeSearchViewModel(type: type, items: items, isTrashMode: isHidden)
        searchVM.coordinator = self
        let searchVC = SearchViewController(vm: searchVM)
        presenter.pushViewController(searchVC, animated: true)
    }
}

// MARK: - VoiceNoteCoordinatorDelegate

extension MainCoordinator: VoiceNoteCoordinatorDelegate {
    func presentMoveFolder(for voiceNote: VoiceNote, onComplete: ((String) -> Void)?) {
        presentMoveFolder(voiceNotes: [voiceNote], onComplete: onComplete, topDetentStyle: .belowSegmentControl)
    }
}

// MARK: - SearchCoordinatorDelegate

extension MainCoordinator: SearchCoordinatorDelegate {
    func pushMyFolderDetailView(_ folder: Folder, isTrashMode: Bool) {
        let myFolderDetailVM = dependencyContainer.makeMyFolderDetailViewModel(folder, isTrashMode: isTrashMode)
        myFolderDetailVM.coordinator = self
        myFolderDetailVM.alertCoordinator = self
        let myFolderDetailVC = FolderDetailViewController(vm: myFolderDetailVM)
        presenter.pushViewController(myFolderDetailVC, animated: true)
    }
}

// MARK: - ChaGokAlertCoordinatorDelegate

extension MainCoordinator: ChaGokAlertCoordinatorDelegate {
    func presentAlert(
        environment: ChaGokAlertViewModel.AlertEnvironment,
        delegate: ChaGokAlertButtonTappedDelegate?
    ) {
        let viewModel = dependencyContainer.makeChaGokAlertViewModel(environment: environment)
        viewModel.coordinator = self
        let alertVC = ChaGokAlertViewController(vm: viewModel)
        alertVC.delegate = delegate
        var topVC: UIViewController = presenter
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        topVC.present(alertVC, animated: true)
    }
}

// MARK: - DownloadWhisperCoordinatorDelegate

extension MainCoordinator: DownloadOnDeviceCoordinatorDelegate {
    func dismissSheet(completion: Bool) {
        if completion { // 모델 다운로드 완료 후
            presenter.dismiss(animated: true) { [weak self] in
                Task {
                    await self?.dependencyContainer.preloadWhisperKit()
                }
            }
        } else {
            presenter.dismiss(animated: true)
        }
    }
}

// MARK: - Helpers

private extension MainCoordinator {
    func presentMoveFolder(
        voiceNotes: [VoiceNote],
        onComplete: ((String) -> Void)?,
        topDetentStyle: MoveFolderCoordinator.TopDetentStyle
    ) {
        let coordinator = MoveFolderCoordinator(
            dependencyContainer: dependencyContainer,
            voiceNotes: voiceNotes,
            onComplete: onComplete,
            topDetentStyle: topDetentStyle,
            onFinish: { [weak self] coordinator in
                self?.free(coordinator: coordinator)
            }
        )
        store(coordinator: coordinator)
        coordinator.start()
        presenter.present(coordinator.presenter, animated: true)
    }
}
