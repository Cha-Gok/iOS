import Domain
import Presentation
import UIKit

@MainActor
final class RecordingCoordinator: BaseCoordinator<UINavigationController> {
    private weak var parentCoordinator: AppCoordinator?
    private let dependencyContainer: AppDIContainer

    init(
        presenter: UINavigationController = UINavigationController(),
        dependencyContainer: AppDIContainer,
        parentCoordinator: AppCoordinator
    ) {
        self.dependencyContainer = dependencyContainer
        self.parentCoordinator = parentCoordinator
        super.init(presenter: presenter)
    }

    override func start() {
        let viewModel = dependencyContainer.makeRecordingViewModel()
        viewModel.coordinator = self
        let recordingVC = RecordingViewController(viewModel: viewModel)
        presenter.modalPresentationStyle = .fullScreen
        presenter.setViewControllers([recordingVC], animated: false)
    }
}

// MARK: - RecordingCoordinating

extension RecordingCoordinator: RecordingCoordinating {
    func cancelRecording() {
        presenter.dismiss(animated: true)
        parentCoordinator?.free(coordinator: self)
    }

    func finishRecording(voiceRecord: VoiceRecord) {
        presenter.dismiss(animated: true)
        parentCoordinator?.free(coordinator: self)
    }
}
