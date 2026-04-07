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
        let mainVC = dependencyContainer.makeMainViewController()
        mainVC.onRecordingButtonTapped = { [weak self] in
            self?.presentRecording()
        }
        presenter.setViewControllers([mainVC], animated: false)
    }

    private func presentRecording() {
        let navController = UINavigationController()
        let viewModel = dependencyContainer.makeRecordingViewModel()
        viewModel.coordinator = self
        let recordingVC = RecordingViewController(viewModel: viewModel)
        navController.modalPresentationStyle = .fullScreen
        navController.setViewControllers([recordingVC], animated: false)
        presenter.present(navController, animated: true)
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
