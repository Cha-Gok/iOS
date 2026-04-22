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
    private let searchBar: VoiceNoteSearchBar = {
        let bar = VoiceNoteSearchBar()
        bar.isHidden = true
        return bar
    }()

    private let matchNavBar: VoiceNoteMatchNavigationBar = {
        let bar = VoiceNoteMatchNavigationBar()
        bar.isHidden = true
        return bar
    }()

    private var matchNavBottomConstraint: NSLayoutConstraint?
    private var segmentedControlTopDefault: NSLayoutConstraint?
    private var segmentedControlTopWhileSearching: NSLayoutConstraint?
    private var searchModeLastApplied = false
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

        addChild(pageViewController)
        pageViewController.setViewControllers([pages[0]], direction: .forward, animated: false)

        view.addSubview(pageViewController.view)
        view.addSubview(bottomFadeView)
        view.addSubview(playerView)
        view.addSubview(segmentedControl)
        view.addSubview(searchBar)
        view.addSubview(matchNavBar)
        view.addSubview(dimOverlayView)

        pageViewController.didMove(toParent: self)

        setupConstraints()
        setupNavigationBar()
        setupTabBar()
        setupPlayerView()
        setupSearchBar()
        setupMatchNavBar()
        setupDimOverlay()
    }

    func setupConstraints() {
        for subview in [pageViewController.view, playerView, segmentedControl, searchBar, matchNavBar, dimOverlayView] {
            subview?.translatesAutoresizingMaskIntoConstraints = false
        }

        let segmentedTopDefault = segmentedControl.topAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.topAnchor,
            constant: 16
        )
        let segmentedTopSearching = segmentedControl.topAnchor.constraint(
            equalTo: searchBar.bottomAnchor,
            constant: 12
        )
        segmentedControlTopDefault = segmentedTopDefault
        segmentedControlTopWhileSearching = segmentedTopSearching

        let matchNavBottom = matchNavBar.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -16
        )
        matchNavBottomConstraint = matchNavBottom

        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: playerView.topAnchor),

            segmentedTopDefault,
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            segmentedControl.heightAnchor.constraint(equalToConstant: 42),

            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            bottomFadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomFadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomFadeView.bottomAnchor.constraint(equalTo: playerView.topAnchor),
            bottomFadeView.heightAnchor.constraint(equalToConstant: 169),

            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            matchNavBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            matchNavBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            matchNavBottom,

            dimOverlayView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            dimOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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
        searchBar.onQueryChanged = { [weak self] query in
            self?.viewModel.updateSearchQuery(query)
        }
        searchBar.onClose = { [weak self] in
            self?.viewModel.exitSearchMode()
        }
    }

    func setupMatchNavBar() {
        matchNavBar.onPrev = { [weak self] in
            self?.viewModel.previousMatch()
        }
        matchNavBar.onNext = { [weak self] in
            self?.viewModel.nextMatch()
        }
    }

    func setupBindings() {
        observePlaybackState()
        observeErrorMessage()
        observeEditingState()
        observeCurrentPage()
        observeSearchState()
        registerKeyboardObservers()
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
            dimOverlayView.isHidden = false
        case .script:
            titleContainerView.isHidden = true
            navigationItem.leftBarButtonItem = editCancelItem
            navigationItem.rightBarButtonItems = [doneItem]
            editCancelItem.tintColor = viewModel.hasScriptEdits ? UIColor.gray950 : UIColor.gray600
            dimOverlayView.isHidden = true
        case nil:
            titleContainerView.setEditing(false)
            titleContainerView.text = viewModel.title
            titleContainerView.isHidden = false
            navigationItem.leftBarButtonItem = backItem
            navigationItem.rightBarButtonItems = [moreItem, searchItem]
            dimOverlayView.isHidden = true
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
            _ = viewModel.currentPage
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

        searchBar.isHidden = !isSearching
        matchNavBar.isHidden = !isSearching
        playerView.isHidden = isSearching
        bottomFadeView.isHidden = isSearching

        segmentedControlTopDefault?.isActive = !isSearching
        segmentedControlTopWhileSearching?.isActive = isSearching

        let summaryCount = isSearching ? viewModel.summaryMatches.count : nil
        let scriptCount = isSearching ? viewModel.scriptMatches.count : nil
        segmentedControl.setCount(summaryCount, at: Page.summary.rawValue)
        segmentedControl.setCount(scriptCount, at: Page.script.rawValue)

        let total = viewModel.currentPageMatches.count
        let displayedIndex = total > 0 ? viewModel.currentMatchIndex + 1 : 0
        matchNavBar.configure(currentIndex: displayedIndex, total: total)

        if isSearching {
            navigationItem.rightBarButtonItems = []
            titleContainerView.isHidden = true
        } else if viewModel.editingMode == nil {
            navigationItem.rightBarButtonItems = [moreItem, searchItem]
            titleContainerView.isHidden = false
        }

        if didToggle {
            if isSearching {
                searchBar.setQuery("")
                searchBar.becomeFirstResponder()
            } else {
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

        view.layoutIfNeeded()
    }
}

// MARK: - Keyboard

private extension VoiceNoteViewController {
    func registerKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(searchKeyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(searchKeyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
}

extension VoiceNoteViewController {
    @objc
    fileprivate func searchKeyboardWillChangeFrame(_ notification: Notification) {
        guard viewModel.searchMode,
              let userInfo = notification.userInfo,
              let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = view.convert(frameValue.cgRectValue, from: nil)
        let overlap = max(0, view.bounds.maxY - keyboardFrame.minY)
        let inset = max(0, overlap - view.safeAreaInsets.bottom)
        applyMatchNavKeyboardInset(inset, userInfo: userInfo)
    }

    @objc
    fileprivate func searchKeyboardWillHide(_ notification: Notification) {
        applyMatchNavKeyboardInset(0, userInfo: notification.userInfo)
    }

    private func applyMatchNavKeyboardInset(_ inset: CGFloat, userInfo: [AnyHashable: Any]?) {
        let duration = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.25
        let curveRaw = (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt)
            ?? UInt(UIView.AnimationCurve.easeInOut.rawValue)
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)
        matchNavBottomConstraint?.constant = -(inset + 16)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.view.layoutIfNeeded()
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
