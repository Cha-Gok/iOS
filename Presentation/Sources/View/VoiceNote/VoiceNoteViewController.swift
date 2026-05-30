import Domain
import UIKit

public final class VoiceNoteViewController: ViewController, Alertable {
    fileprivate typealias Page = VoiceNoteViewModel.Page

    private let viewModel: VoiceNoteViewModel

    // MARK: - UI Components

    private let navigationBar = VoiceNoteNavigationBar()
    private let playerView = AudioPlayerView()
    private let segmentedControl = UnderlineSegmentedControl(items: Page.allCases.map(\.title))
    private let matchAccessoryBar: VoiceNoteMatchAccessoryBar = {
        let bar = VoiceNoteMatchAccessoryBar()
        bar.isHidden = true
        return bar
    }()

    private lazy var dimOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.dimBackground
        view.isHidden = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(dimOverlayTapped))
        view.addGestureRecognizer(tap)

        return view
    }()

    private lazy var pageViewController: UIPageViewController = {
        let pvc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pvc.dataSource = self
        pvc.delegate = self
        pvc.setViewControllers([summaryViewController], direction: .forward, animated: false)
        return pvc
    }()

    private lazy var summaryViewController = VoiceNoteSummaryViewController(viewModel: viewModel)
    private lazy var scriptViewController = VoiceNoteScriptViewController(viewModel: viewModel)
    private lazy var pages: [UIViewController] = [summaryViewController, scriptViewController]

    private let contentBottomGuide = UILayoutGuide()
    private lazy var contentBottomToPlayerTop = contentBottomGuide.topAnchor.constraint(equalTo: playerView.topAnchor)
    private lazy var contentBottomToViewBottom = contentBottomGuide.topAnchor.constraint(equalTo: view.bottomAnchor)
    private lazy var pageTopToSegmentBottom = pageViewController.view.topAnchor.constraint(
        equalTo: segmentedControl.bottomAnchor
    )
    private lazy var pageTopToSafeArea = pageViewController.view.topAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.topAnchor
    )

    // MARK: - Init

    public init(viewModel: VoiceNoteViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

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
        updateNavigationBarAppearance(isTransparent: false)
        addChild(pageViewController)
        pageViewController.didMove(toParent: self)

        view.addSubview(segmentedControl)
        view.addSubview(pageViewController.view)
        view.addSubview(playerView)

        view.addSubview(dimOverlayView)
        view.addSubview(matchAccessoryBar)

        setupConstraints()
        setupNavigationBar()
        setupTabBar()
        setupPlayerView()
        setupMatchAccessoryBar()
    }

    func setupConstraints() {
        for subview in [
            pageViewController.view,
            playerView,
            segmentedControl,
            dimOverlayView,
            matchAccessoryBar
        ] {
            subview?.translatesAutoresizingMaskIntoConstraints = false
        }

        view.addLayoutGuide(contentBottomGuide)

        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: contentBottomGuide.topAnchor),

            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentBottomGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentBottomGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentBottomGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dimOverlayView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            dimOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            matchAccessoryBar.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Constant.matchAccessoryBarHorizontalMargin
            ),
            matchAccessoryBar.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Constant.matchAccessoryBarHorizontalMargin
            ),
            matchAccessoryBar.bottomAnchor.constraint(
                equalTo: view.keyboardLayoutGuide.topAnchor,
                constant: -Constant.matchAccessoryBarKeyboardSpacing
            )
        ])

        pageTopToSegmentBottom.isActive = true
        contentBottomToPlayerTop.isActive = true
    }

    @objc
    func dimOverlayTapped() {
        viewModel.doneTitleEditing(title: navigationBar.titleText)
    }

    func setupNavigationBar() {
        navigationBar.onBack = { [weak self] in
            self?.viewModel.pop()
        }
        navigationBar.onEditCancel = { [weak self] in
            self?.viewModel.cancelEditing()
        }
        navigationBar.onDoneTitle = { [weak self] title in
            self?.viewModel.doneTitleEditing(title: title)
        }
        navigationBar.onDoneScript = { [weak self] in
            self?.view.makeToast(type: .normal, "스크립트가 수정되었어요.")
            self?.viewModel.doneScriptEditing()
        }

        // TODO: - 완료 핸들러 안해도 될듯.
        navigationBar.onMove = { [weak self] in
            self?.viewModel.moveVoiceNote { [weak self] name in
                self?.view.makeToast(type: .normal, "`\(name)` 폴더로 이동됐어요.")
            }
        }
        navigationBar.onEditScript = { [weak self] in
            self?.viewModel.enterScriptEditing()
        }
        navigationBar.onDelete = { [weak self] in
            self?.viewModel.deleteVoiceNote()
        }
        navigationBar.onTapTitle = { [weak self] in
            self?.viewModel.enterTitleEditing()
        }
        navigationBar.onSearchEnter = { [weak self] in
            self?.viewModel.enterSearchMode()
        }
        navigationBar.onSearchQuery = { [weak self] query in
            self?.viewModel.updateSearchQuery(query)
        }
        navigationBar.onSearchClose = { [weak self] in
            self?.viewModel.exitSearchMode()
        }

        navigationBar.apply(to: navigationItem, title: viewModel.title, isTrashMode: viewModel.isTrashMode)
    }

    func setupTabBar() {
        segmentedControl.onSegmentSelected = { [weak self] index in
            guard let self, let page = Page(rawValue: index) else { return }
            viewModel.updateCurrentPage(page)
        }
    }

    func setupPlayerView() {
        playerView.onPlayPause = { [weak self] in self?.viewModel.playPause() }
        playerView.onRewind = { [weak self] in self?.viewModel.rewind() }
        playerView.onForward = { [weak self] in self?.viewModel.forward() }
        playerView.onSeekBegan = { [weak self] in self?.viewModel.seekBegan() }
        playerView.onSeekEnded = { [weak self] time in self?.viewModel.seekEnded(time) }
    }

    func setupMatchAccessoryBar() {
        matchAccessoryBar.onPrev = { [weak self] in
            self?.viewModel.previousMatch()
        }
        matchAccessoryBar.onNext = { [weak self] in
            self?.viewModel.nextMatch()
        }
    }

    func setupBindings() {
        observePlaybackState()
        observeErrorMessage()
        observeEditingState()
        observeCurrentPage()
        observeSearchState()
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

    func observeEditingState() {
        withObservationTracking {
            _ = viewModel.editingMode
            _ = viewModel.hasScriptEdits
        } onChange: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.applyEditingMode()
                self.observeEditingState()
            }
        }
    }

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

    func observeSearchState() {
        withObservationTracking {
            _ = viewModel.searchMode
            _ = viewModel.searchQuery
            _ = viewModel.currentMatchIndex
        } onChange: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.applySearchState()
                self.observeSearchState()
            }
        }
    }

    func applyEditingMode() {
        let isScriptEditing = viewModel.editingMode == .script

        dimOverlayView.isHidden = viewModel.editingMode != .title
        segmentedControl.isHidden = isScriptEditing
        playerView.isHidden = isScriptEditing || viewModel.searchMode

        pageTopToSegmentBottom.isActive = !isScriptEditing
        pageTopToSafeArea.isActive = isScriptEditing

        if !viewModel.searchMode {
            contentBottomToPlayerTop.isActive = !isScriptEditing
            contentBottomToViewBottom.isActive = isScriptEditing
        }

        navigationBar.apply(
            to: navigationItem,
            title: viewModel.title,
            editingMode: viewModel.editingMode,
            searchMode: viewModel.searchMode,
            hasScriptEdits: viewModel.hasScriptEdits,
            isTrashMode: viewModel.isTrashMode
        )
    }

    func applySearchState() {
        let isSearching = viewModel.searchMode

        segmentedControl.setCount(viewModel.summaryMatchCount, at: Page.summary.rawValue)
        segmentedControl.setCount(viewModel.scriptMatchCount, at: Page.script.rawValue)

        matchAccessoryBar.configure(
            countText: viewModel.matchCountText,
            hasMatches: viewModel.hasCurrentPageMatches
        )

        let didToggle = navigationBar.apply(
            to: navigationItem,
            title: viewModel.title,
            editingMode: viewModel.editingMode,
            searchMode: isSearching,
            hasScriptEdits: viewModel.hasScriptEdits,
            isTrashMode: viewModel.isTrashMode
        )

        if didToggle {
            let isScriptEditing = viewModel.editingMode == .script
            playerView.isHidden = isSearching || isScriptEditing
            matchAccessoryBar.isHidden = !isSearching
            contentBottomToPlayerTop.isActive = !isSearching && !isScriptEditing
            contentBottomToViewBottom.isActive = isSearching || isScriptEditing
        }

        if let match = viewModel.currentMatch {
            switch match.location {
            case .keyPoint, .keyword:
                summaryViewController.scrollToMatch(match)
            case .script:
                scriptViewController.scrollToMatch(match)
            }
        }
    }

    func applyCurrentPage(_ page: Page) {
        segmentedControl.selectSegment(index: page.rawValue)

        let target = pages[page.rawValue]
        if let current = pageViewController.viewControllers?.first,
           let currentIndex = pages.firstIndex(of: current),
           current !== target
        {
            let direction: UIPageViewController.NavigationDirection = page.rawValue > currentIndex ? .forward : .reverse
            pageViewController.setViewControllers([target], direction: direction, animated: true)
        }

        if viewModel.searchMode {
            applySearchState()
        }
    }
}

// MARK: - UIPageViewControllerDataSource / Delegate

extension VoiceNoteViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard viewModel.editingMode == nil,
              let idx = pages.firstIndex(of: viewController), idx > 0 else { return nil }
        return pages[idx - 1]
    }

    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard viewModel.editingMode == nil,
              let idx = pages.firstIndex(of: viewController), idx < pages.count - 1 else { return nil }
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

#if DEBUG
    #Preview("보이스 노트") {
        UINavigationController(
            rootViewController: VoiceNoteViewController(viewModel: .preview())
        )
    }
#endif
