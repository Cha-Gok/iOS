import Core
import Domain
import Presentation
import UIKit

@MainActor
final class MoveFolderCoordinator: BaseCoordinator<UINavigationController> {
    enum TopDetentStyle {
        /// 부모 네비게이션 바 바로 아래까지.
        case belowNavigationBar
        /// VoiceNote 상세의 세그먼트 컨트롤 바로 아래까지.
        case belowSegmentControl
    }

    private let dependencyContainer: AppDIContainer
    private let voiceNotes: [VoiceNote]
    private let onComplete: ((String) -> Void)?
    private let topDetentStyle: TopDetentStyle
    private let onFinish: (MoveFolderCoordinator) -> Void

    init(
        dependencyContainer: AppDIContainer,
        voiceNotes: [VoiceNote],
        onComplete: ((String) -> Void)?,
        topDetentStyle: TopDetentStyle = .belowNavigationBar,
        onFinish: @escaping (MoveFolderCoordinator) -> Void
    ) {
        self.dependencyContainer = dependencyContainer
        self.voiceNotes = voiceNotes
        self.onComplete = onComplete
        self.topDetentStyle = topDetentStyle
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
            sheet.detents = moveFolderListDetents
            sheet.prefersGrabberVisible = true
        }
    }

    /// 부모 화면 상단 safe area + `topDetentStyle`에 해당하는 추가 inset만큼 아래까지 올라오는 커스텀 detent 포함.
    private var moveFolderListDetents: [UISheetPresentationController.Detent] {
        let additionalTopInset = additionalTopInset(for: topDetentStyle)
        return [
            .medium(),
            .custom(identifier: .init("belowParentTop")) { [weak presenter, additionalTopInset] context in
                guard let parentNav = presenter?.presentingViewController as? UINavigationController,
                      let topView = parentNav.topViewController?.view,
                      let window = topView.window
                else {
                    return context.maximumDetentValue
                }
                let sheetTopY = topView.safeAreaInsets.top + additionalTopInset
                let sheetHeight = window.bounds.height - sheetTopY
                return min(sheetHeight, context.maximumDetentValue)
            }
        ]
    }

    private func additionalTopInset(for style: TopDetentStyle) -> CGFloat {
        switch style {
        case .belowNavigationBar:
            return 0
        case .belowSegmentControl:
            return Constant.underlineSegmentedControlTopMargin + Constant.underlineSegmentedControlHeight
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
            sheet.detents = moveFolderListDetents
        }
    }

    func folderCreated() {
        guard let sheet = presenter.sheetPresentationController else { return }

        presenter.popViewController(animated: true)

        sheet.animateChanges {
            sheet.detents = moveFolderListDetents
        }
    }
}
