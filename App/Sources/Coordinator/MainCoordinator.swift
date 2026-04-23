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
    
    func pushSearchView() {
        let searchVM = dependencyContainer.makeSearchViewModel()
        let searchVC = SearchViewController(vm: searchVM)
        
        presenter.pushViewController(searchVC, animated: true)
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

// MARK: - FolderCoordinatorDelegate

extension MainCoordinator: FolderCoordinatorDelegate {
    func pop() {
        presenter.popViewController(animated: true)
    }

    func pushMyFolderDetailView(_ folder: Folder) {
        let myFolderDetailVM = dependencyContainer.makeMyFolderDetailViewModel(folder)
        myFolderDetailVM.coordinator = self
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

extension MainCoordinator: TrashCoordinatorDelegate {}

// MARK: - VoiceNoteCoordinatorDelegate

extension MainCoordinator: VoiceNoteCoordinatorDelegate {
    func presentMoveFolder(for voiceNote: VoiceNote, onComplete: ((String) -> Void)?) {
        presentMoveFolder(voiceNotes: [voiceNote], onComplete: onComplete, topDetentStyle: .belowSegmentControl)
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
