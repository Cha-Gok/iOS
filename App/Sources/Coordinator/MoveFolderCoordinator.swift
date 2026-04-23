import Core
import Domain
import Presentation
import UIKit

@MainActor
final class MoveFolderCoordinator: BaseCoordinator<UINavigationController> {
    private let dependencyContainer: AppDIContainer
    private let voiceNotes: [VoiceNote]
    private let onComplete: ((String) -> Void)?
    private let onFinish: (MoveFolderCoordinator) -> Void

    init(
        parentPresenter: UINavigationController,
        dependencyContainer: AppDIContainer,
        voiceNotes: [VoiceNote],
        onComplete: ((String) -> Void)?,
        onFinish: @escaping (MoveFolderCoordinator) -> Void
    ) {
        self.dependencyContainer = dependencyContainer
        self.voiceNotes = voiceNotes
        self.onComplete = onComplete
        self.onFinish = onFinish

        let nav = UINavigationController()
        nav.isNavigationBarHidden = true
        super.init(presenter: nav)
    }

    override func start() {
        let viewModel = dependencyContainer.makeMoveFolderListViewModel(
            voiceNotes: voiceNotes,
            onComplete: onComplete
        )
        viewModel.coordinator = self
        let viewController = MoveFolderListViewController(viewModel: viewModel)
        presenter.setViewControllers([viewController], animated: false)

        if let sheet = presenter.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
    }
}

// MARK: - MoveFolderListCoordinatorDelegate

extension MoveFolderCoordinator: MoveFolderListCoordinatorDelegate {
    func dismiss() {
        presenter.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            onFinish(self)
        }
    }

    func pushNewFolder() {
        guard let sheet = presenter.sheetPresentationController else { return }

        let viewModel = dependencyContainer.makeNewFolderViewModel()
        viewModel.coordinator = self
        let newFolderVC = NewFolderViewController(viewModel: viewModel)
        newFolderVC.view.layoutIfNeeded()

        presenter.pushViewController(newFolderVC, animated: true)

        sheet.animateChanges {
            sheet.detents = [.custom { [weak newFolderVC] _ in
                newFolderVC?.preferredContentSize.height
            }]
        }
    }
}

// MARK: - NewFolderCoordinatorDelegate

extension MoveFolderCoordinator: NewFolderCoordinatorDelegate {
    func cancel() {
        guard let sheet = presenter.sheetPresentationController else { return }

        presenter.popViewController(animated: true)

        sheet.animateChanges {
            sheet.detents = [.medium()]
        }
    }

    func folderCreated() {
        guard let sheet = presenter.sheetPresentationController else { return }

        presenter.popViewController(animated: true)

        sheet.animateChanges {
            sheet.detents = [.medium()]
        }
    }
}
