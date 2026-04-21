import Domain
import SwiftUI
import UIKit

public final class VoiceNoteViewController: UIViewController, Alertable {
    fileprivate typealias Page = VoiceNoteViewModel.Page

    private let viewModel: VoiceNoteViewModel

    // MARK: - UI Components

    private let titleContainerView = NavigationTitleContainerView()
    private let playerView = AudioPlayerView()
    private let segmentedControl = UnderlineSegmentedControl(items: Page.allCases.map(\.title))

    private let backItem = UIBarButtonItem(image: .chevronLeft)
    private let editCancelItem = UIBarButtonItem(image: .cornerUpLeft)
    private let doneItem = UIBarButtonItem(title: "완료")
    private let moreItem = UIBarButtonItem(image: .moreVertical)
    private let searchItem = UIBarButtonItem(image: .search)

    private lazy var pageViewController: UIPageViewController = {
        let pvc = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        pvc.dataSource = self
        pvc.delegate = self
        return pvc
    }()

    private lazy var summaryViewController = VoiceNoteSummaryViewController(viewModel: viewModel)
    private lazy var scriptViewController = VoiceNoteScriptViewController(viewModel: viewModel)
    private lazy var pages: [UIViewController] = [summaryViewController, scriptViewController]

    // MARK: - Init

    public init(viewModel: VoiceNoteViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        viewModel.onAppear()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.onDisappear()
    }
}

// MARK: - Setup

private extension VoiceNoteViewController {
    func setupUI() {
        view.backgroundColor = UIColor.gray0

        addChild(pageViewController)
        pageViewController.setViewControllers([pages[0]], direction: .forward, animated: false)

        view.addSubview(pageViewController.view)
        view.addSubview(playerView)
        view.addSubview(segmentedControl)

        pageViewController.didMove(toParent: self)

        setupConstraints()
        setupNavigationBar()
        setupTabBar()
        setupPlayerView()
    }

    func setupConstraints() {
        for subview in [pageViewController.view, playerView, segmentedControl] {
            subview?.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: playerView.topAnchor),

            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            segmentedControl.heightAnchor.constraint(equalToConstant: 42),

            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func setupTitleContainer() {
        titleContainerView.text = viewModel.title
        titleContainerView.onTapTitle = { [weak self] in
            self?.viewModel.enterTitleEditing()
        }
        titleContainerView.onShouldBeginEditing = { [weak self] in
            guard let self, viewModel.editingMode == nil else { return }
            viewModel.enterTitleEditing()
        }
        titleContainerView.onCommit = { [weak self] text in
            self?.viewModel.doneTitleEditing(title: text)
        }
    }

    func setupNavigationBar() {
        setupTitleContainer()

        for item in [backItem, editCancelItem, doneItem, moreItem, searchItem] {
            item.hidesSharedBackground = true
        }
        backItem.tintColor = UIColor.gray950
        doneItem.tintColor = UIColor.point800
        [moreItem, searchItem].forEach { $0.tintColor = .white }

        backItem.primaryAction = UIAction { [weak self] _ in
            self?.viewModel.pop()
        }
        editCancelItem.primaryAction = UIAction { [weak self] _ in
            self?.viewModel.cancelEditing()
        }
        doneItem.primaryAction = UIAction { [weak self] _ in
            guard let self else { return }
            switch viewModel.editingMode {
            case .title:
                viewModel.doneTitleEditing(title: titleContainerView.text ?? "")
            case .script:
                viewModel.doneScriptEditing()
            case nil:
                break
            }
        }
        moreItem.menu = UIMenu(children: [
            UIAction(title: "기록 이동하기") { [weak self] _ in
                self?.viewModel.moveVoiceNote()
            },
            UIAction(title: "편집하기") { [weak self] _ in
                self?.viewModel.enterScriptEditing()
            },
            UIAction(title: "삭제하기", attributes: .destructive) { [weak self] _ in
                self?.viewModel.deleteVoiceNote()
            }
        ])

        navigationItem.leftBarButtonItem = backItem
        navigationItem.titleView = titleContainerView
        navigationItem.rightBarButtonItems = [moreItem, searchItem]
    }

    func setupTabBar() {
        segmentedControl.addAction(UIAction { [weak self] _ in
            guard let self, let page = Page(rawValue: segmentedControl.selectedSegmentIndex) else { return }
            viewModel.updateCurrentPage(page)
        }, for: .valueChanged)
    }

    func setupPlayerView() {
        playerView.onPlayPause = { [weak self] in self?.viewModel.playPause() }
        playerView.onRewind = { [weak self] in self?.viewModel.rewind() }
        playerView.onForward = { [weak self] in self?.viewModel.forward() }
        playerView.onSeekBegan = { [weak self] in self?.viewModel.seekBegan() }
        playerView.onSeekEnded = { [weak self] time in self?.viewModel.seekEnded(time) }
    }

    func setupBindings() {
        observePlaybackState()
        observeErrorMessage()
        observeEditingState()
        observeCurrentPage()
    }

    func observePlaybackState() {
        withObservationTracking {
            _ = viewModel.currentPlaybackState
        } onChange: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.playerView.apply(self.viewModel.currentPlaybackState)
                self.observePlaybackState()
            }
        }
    }

    func observeErrorMessage() {
        withObservationTracking {
            _ = viewModel.errorMessage
        } onChange: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                if let message = self.viewModel.errorMessage {
                    self.showAlert(title: "오류", message: message) { [weak self] in
                        self?.viewModel.dismissError()
                    }
                }
                self.observeErrorMessage()
            }
        }
    }
}

// MARK: - Page Switching

private extension VoiceNoteViewController {
    func observeCurrentPage() {
        withObservationTracking {
            _ = viewModel.currentPage
        } onChange: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.applyCurrentPage(self.viewModel.currentPage)
                self.observeCurrentPage()
            }
        }
    }

    func applyCurrentPage(_ page: Page) {
        segmentedControl.selectSegment(index: page.rawValue)

        let target = pages[page.rawValue]
        guard let current = pageViewController.viewControllers?.first,
              let currentIndex = pages.firstIndex(of: current),
              current !== target else { return }

        let direction: UIPageViewController.NavigationDirection = page.rawValue > currentIndex ? .forward : .reverse
        pageViewController.setViewControllers([target], direction: direction, animated: true)
    }
}

// MARK: - UIPageViewControllerDataSource / Delegate

extension VoiceNoteViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let idx = pages.firstIndex(of: viewController), idx > 0 else { return nil }
        return pages[idx - 1]
    }

    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let idx = pages.firstIndex(of: viewController), idx < pages.count - 1 else { return nil }
        return pages[idx + 1]
    }

    public func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let current = pageViewController.viewControllers?.first,
              let index = pages.firstIndex(of: current),
              let page = Page(rawValue: index)
        else { return }
        viewModel.updateCurrentPage(page)
    }
}

// MARK: - Edit Mode

private extension VoiceNoteViewController {
    func observeEditingState() {
        withObservationTracking {
            _ = viewModel.editingMode
            _ = viewModel.hasScriptEdits
        } onChange: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                applyEditingMode(viewModel.editingMode)
                observeEditingState()
            }
        }
    }
}

private extension VoiceNoteViewController {
    func applyEditingMode(_ mode: VoiceNoteViewModel.EditingMode?) {
        switch mode {
        case .title:
            if !titleContainerView.isEditingTitle {
                titleContainerView.text = viewModel.title
                titleContainerView.setEditing(true)
            }
            navigationItem.rightBarButtonItems = [doneItem]
        case .script:
            titleContainerView.isHidden = true
            navigationItem.leftBarButtonItem = editCancelItem
            navigationItem.rightBarButtonItems = [doneItem]
            editCancelItem.tintColor = viewModel.hasScriptEdits ? UIColor.gray950 : UIColor.gray600
        case nil:
            titleContainerView.setEditing(false)
            titleContainerView.text = viewModel.title
            titleContainerView.isHidden = false
            navigationItem.leftBarButtonItem = backItem
            navigationItem.rightBarButtonItems = [moreItem, searchItem]
        }
    }
}

#if DEBUG
    #Preview("보이스 노트") {
        UINavigationController(
            rootViewController: VoiceNoteViewController(viewModel: .preview())
        )
    }
#endif
