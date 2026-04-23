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
    private let bottomFadeView = VoiceNoteBottomFadeView()
    private let searchBar = VoiceNoteSearchBar()
    private let matchAccessoryBar = VoiceNoteMatchAccessoryBar()

    private var searchModeLastApplied = false
    private let contentBottomGuide = UILayoutGuide()
    private var contentBottomToPlayerTop: NSLayoutConstraint?
    private var contentBottomToViewBottom: NSLayoutConstraint?
    private let dimOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.dimBackground
        view.isHidden = true
        return view
    }()

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

        view.addSubview(pageViewController.view)
        view.addSubview(bottomFadeView)
        view.addSubview(playerView)
        view.addSubview(segmentedControl)
        view.addSubview(dimOverlayView)
        view.addSubview(matchAccessoryBar)
        matchAccessoryBar.isHidden = true

        addChild(pageViewController)
        pageViewController.setViewControllers([pages[0]], direction: .forward, animated: false)
        pageViewController.didMove(toParent: self)

        setupConstraints()
        setupNavigationBar()
        setupTabBar()
        setupPlayerView()
        setupSearchBar()
        setupDimOverlay()
    }

    func setupConstraints() {
        for subview in [
            pageViewController.view,
            playerView,
            segmentedControl,
            bottomFadeView,
            dimOverlayView,
            matchAccessoryBar
        ] {
            subview?.translatesAutoresizingMaskIntoConstraints = false
        }

        view.addLayoutGuide(contentBottomGuide)

        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: contentBottomGuide.topAnchor),

            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            segmentedControl.heightAnchor.constraint(equalToConstant: 42),

            bottomFadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomFadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomFadeView.heightAnchor.constraint(equalToConstant: 169),
            bottomFadeView.bottomAnchor.constraint(equalTo: contentBottomGuide.topAnchor),

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

            matchAccessoryBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            matchAccessoryBar.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -20
            ),
            matchAccessoryBar.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -8)
        ])

        contentBottomToPlayerTop = contentBottomGuide.topAnchor.constraint(equalTo: playerView.topAnchor)
        contentBottomToViewBottom = contentBottomGuide.topAnchor.constraint(equalTo: view.bottomAnchor)
        contentBottomToPlayerTop?.isActive = true
    }

    func setupDimOverlay() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dimOverlayTapped))
        dimOverlayView.addGestureRecognizer(tap)
    }

    @objc
    func dimOverlayTapped() {
        viewModel.doneTitleEditing(title: titleContainerView.text ?? "")
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
        searchItem.primaryAction = UIAction { [weak self] _ in
            self?.viewModel.enterSearchMode()
        }

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

    func setupSearchBar() {
        searchBar.onReturn = { [weak self] query in
            self?.viewModel.updateSearchQuery(query)
        }
        searchBar.onClose = { [weak self] in
            self?.viewModel.exitSearchMode()
        }
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
            dimOverlayView.isHidden = false
        case .script:
            titleContainerView.isHidden = true
            editCancelItem.tintColor = viewModel.hasScriptEdits ? UIColor.gray950 : UIColor.gray600
            dimOverlayView.isHidden = true
        case nil:
            titleContainerView.setEditing(false)
            titleContainerView.text = viewModel.title
            titleContainerView.isHidden = false
            dimOverlayView.isHidden = true
        }
        updateNavigationItems()
    }

    func updateNavigationItems() {
        if viewModel.searchMode {
            navigationItem.hidesBackButton = true
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItems = []
            navigationItem.titleView = searchBar
            return
        }

        navigationItem.hidesBackButton = false
        navigationItem.titleView = titleContainerView
        switch viewModel.editingMode {
        case .title:
            navigationItem.leftBarButtonItem = backItem
            navigationItem.rightBarButtonItems = [doneItem]
        case .script:
            navigationItem.leftBarButtonItem = editCancelItem
            navigationItem.rightBarButtonItems = [doneItem]
        case nil:
            navigationItem.leftBarButtonItem = backItem
            navigationItem.rightBarButtonItems = [moreItem, searchItem]
        }
    }
}

// MARK: - Search Mode

private extension VoiceNoteViewController {
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

    func applySearchState() {
        let isSearching = viewModel.searchMode
        let didToggle = isSearching != searchModeLastApplied
        searchModeLastApplied = isSearching

        segmentedControl.setCount(viewModel.summaryMatchCount, at: Page.summary.rawValue)
        segmentedControl.setCount(viewModel.scriptMatchCount, at: Page.script.rawValue)

        matchAccessoryBar.configure(
            countText: viewModel.matchCountText,
            hasMatches: viewModel.hasCurrentPageMatches
        )

        updateNavigationItems()

        if didToggle {
            playerView.isHidden = isSearching
            matchAccessoryBar.isHidden = !isSearching
            contentBottomToPlayerTop?.isActive = !isSearching
            contentBottomToViewBottom?.isActive = isSearching
            if isSearching {
                searchBar.becomeFirstResponder()
            } else {
                searchBar.setQuery("")
                searchBar.resignFirstResponder()
            }
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
}

#if DEBUG
    #Preview("보이스 노트") {
        UINavigationController(
            rootViewController: VoiceNoteViewController(viewModel: .preview())
        )
    }
#endif
