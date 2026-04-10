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
        myFolderVM.folderCoordinator = self
        let myFolderVC = FolderViewController(vm: myFolderVM)
        presenter.pushViewController(myFolderVC, animated: true)
    }

    // TODO: Present

    func presentRecodingView() {
        Task {
            let checkUseCase = dependencyContainer.makeCheckMicrophonePermissionUseCase()
            let requestUseCase = dependencyContainer.makeRequestMicrophonePermissionUseCase()

            do {
                let status = try await checkUseCase.execute()

                switch status {
                case .authorized:
                    showRecordingView()
                case .denied:
                    showPermissionDeniedAlert()
                case .notDetermined:
                    let grantedStatus = try await requestUseCase.execute()
                    if grantedStatus == .authorized {
                        showRecordingView()
                    }
                }
            } catch {
                AppLogger.error(error)
            }
        }
    }

    private func showRecordingView() {
        let navController = UINavigationController()
        let viewModel = dependencyContainer.makeRecordingViewModel()
        viewModel.coordinator = self
        let recordingVC = RecordingViewController(viewModel: viewModel)
        navController.modalPresentationStyle = .fullScreen
        navController.setViewControllers([recordingVC], animated: false)
        presenter.present(navController, animated: true)
    }

    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "마이크 권한 필요",
            message: "녹음을 위해 마이크 권한이 필요합니다. 설정에서 권한을 허용해주세요.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })

        presenter.present(alert, animated: true)
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

// MARK: Base 공통 함수 묶음

extension MainCoordinator: BaseCoordinatorDelegate {
    // TODO: Pop

    func pop() {
        presenter.popViewController(animated: true)
    }
}
