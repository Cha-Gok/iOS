import Domain
import UIKit

public final class VoiceNoteViewController: UIViewController, Alertable {
    let viewModel: VoiceNoteViewModel

    // MARK: - UI Components

    private let playerView = AudioPlayerView()
    private let topBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private lazy var segmentedControl = UnderlineSegmentedControl(items: Page.allCases.map(\.title))
    private lazy var backChevronButton: UIButton = {
        let btn = UIButton(type: .system)
        let backImage = UIImage(systemName: "chevron.left")?
            .withConfiguration(UIImage.SymbolConfiguration(weight: .bold))
        btn.setImage(backImage, for: .normal)
        btn.tintColor = UIColor.gray950
        btn.addAction(UIAction { [weak self] _ in
            self?.viewModel.pop()
        }, for: .touchUpInside)
        return btn
    }()

    private lazy var editCancelButton: UIBarButtonItem = UIBarButtonItem(
        image: .cornerUpLeft,
        primaryAction: UIAction { [weak self] _ in
            self?.viewModel.cancelEditing()
        }
    )

    private lazy var titleField: TypographyTextField = {
        let field = TypographyTextField(typography: .title1)
        field.textColor = UIColor.gray950
        field.tintColor = UIColor.gray950
        field.returnKeyType = .done
        field.delegate = self
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let tap = UITapGestureRecognizer(target: self, action: #selector(titleFieldTapped))
        field.addGestureRecognizer(tap)
        return field
    }()

    @objc
    private func titleFieldTapped() {
        viewModel.enterTitleEditing()
    }

    private lazy var doneButton: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "완료", primaryAction: UIAction { [weak self] _ in
            guard let self else { return }
            switch viewModel.editingMode {
            case .title:
                viewModel.doneTitleEditing(title: titleField.text ?? "")
            case .script:
                viewModel.doneScriptEditing()
            case nil:
                break
            }
        })
        item.tintColor = UIColor.point800
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.08
        let attrs: [NSAttributedString.Key: Any] = [.paragraphStyle: paragraphStyle]
        item.setTitleTextAttributes(attrs, for: .normal)
        item.setTitleTextAttributes(attrs, for: .highlighted)
        return item
    }()

    private var normalLeftBarButtonItem: UIBarButtonItem?
    private var normalRightBarButtonItems: [UIBarButtonItem] = []

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
    private var currentPageIndex: Int = 0

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

        addPageViewController()
        view.addSubview(playerView)
        view.addSubview(topBlurView)
        view.addSubview(segmentedControl)

        setupConstraints()
        setupNavigationBar()
        setupTabBar()
        setupPlayerView()
        setupBindings()
    }

    func addPageViewController() {
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        pageViewController.setViewControllers(
            [pages[0]],
            direction: .forward,
            animated: false
        )
    }

    func setupConstraints() {
        for subview in [pageViewController.view!, playerView, topBlurView, segmentedControl] {
            subview.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: playerView.topAnchor),

            topBlurView.topAnchor.constraint(equalTo: view.topAnchor),
            topBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBlurView.bottomAnchor.constraint(equalTo: segmentedControl.bottomAnchor),

            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            segmentedControl.heightAnchor.constraint(equalToConstant: 42),

            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func setupNavigationBar() {
        titleField.text = viewModel.title
        titleField.frame.size.width = view.bounds.width
        let menu = UIMenu(children: [
            UIAction(title: "기록 이동하기", handler: { [weak self] _ in
                self?.viewModel.moveVoiceNote()
            }),
            UIAction(title: "편집하기", handler: { [weak self] _ in
                self?.viewModel.enterScriptEditing()
            }),
            UIAction(title: "삭제하기", attributes: .destructive, handler: { [weak self] _ in
                self?.viewModel.deleteVoiceNote()
            })
        ])
        let moreItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: menu)
        let searchItem = UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass"),
            style: .plain,
            target: nil,
            action: nil
        )
        normalRightBarButtonItems = [moreItem, searchItem]
        normalLeftBarButtonItem = UIBarButtonItem(customView: backChevronButton)
        navigationItem.leftBarButtonItem = normalLeftBarButtonItem
        navigationItem.titleView = titleField
        navigationItem.rightBarButtonItems = normalRightBarButtonItems
        navigationItem.rightBarButtonItems?.forEach { $0.tintColor = .white }
        navigationItem.leftBarButtonItem?.hidesSharedBackground = true
        navigationItem.rightBarButtonItems?.forEach { $0.hidesSharedBackground = true }
    }

    func setupTabBar() {
        segmentedControl.addAction(UIAction { [weak self] action in
            guard let self, let sender = action.sender as? UnderlineSegmentedControl else { return }
            let index = sender.selectedSegmentIndex
            switchToPage(at: index, animated: true)
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
        observeScriptEdits()
    }

    func observeScriptEdits() {
        withObservationTracking {
            _ = viewModel.hasScriptEdits
        } onChange: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.updateEditCancelButtonTint()
                self.observeScriptEdits()
            }
        }
    }

    func updateEditCancelButtonTint() {
        editCancelButton.tintColor = viewModel.hasScriptEdits ? UIColor.gray950 : UIColor.gray600
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
    func switchToPage(at index: Int, animated: Bool) {
        guard pages.indices.contains(index), index != currentPageIndex else { return }
        let direction: UIPageViewController.NavigationDirection = index > currentPageIndex ? .forward : .reverse
        pageViewController.setViewControllers(
            [pages[index]],
            direction: direction,
            animated: animated
        )
        currentPageIndex = index
    }

    func syncSegmentedControl(to index: Int) {
        guard segmentedControl.selectedSegmentIndex != index else { return }
        segmentedControl.selectSegment(index: index)
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
              let idx = pages.firstIndex(of: current) else { return }
        currentPageIndex = idx
        syncSegmentedControl(to: idx)
    }
}

// MARK: - Edit Mode

private extension VoiceNoteViewController {
    func observeEditingState() {
        withObservationTracking {
            _ = viewModel.editingMode
        } onChange: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.applyEditingMode(self.viewModel.editingMode)
                self.observeEditingState()
            }
        }
    }
}

private extension VoiceNoteViewController {
    func applyEditingMode(_ mode: VoiceNoteViewModel.EditingMode?) {
        switch mode {
        case .title:
            enterTitleEditMode()
        case .script:
            enterScriptEditMode()
        case nil:
            exitEditMode()
        }
    }

    func enterTitleEditMode() {
        navigationItem.rightBarButtonItems = [doneButton]
        titleField.becomeFirstResponder()
        titleField.selectAll(nil as Any?)
    }

    func enterScriptEditMode() {
        navigationItem.titleView = nil
        navigationItem.leftBarButtonItem = editCancelButton
        navigationItem.rightBarButtonItems = [doneButton]
        updateEditCancelButtonTint()
        switchToPage(at: Page.script.rawValue, animated: true)
        syncSegmentedControl(to: Page.script.rawValue)
    }

    func exitEditMode() {
        view.endEditing(true)
        titleField.text = viewModel.title
        navigationItem.titleView = titleField
        navigationItem.leftBarButtonItem = normalLeftBarButtonItem
        navigationItem.rightBarButtonItems = normalRightBarButtonItems
        navigationItem.rightBarButtonItems?.forEach { $0.tintColor = .white }
    }
}

// MARK: - UITextFieldDelegate

extension VoiceNoteViewController: UITextFieldDelegate {
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        viewModel.editingMode == .title
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        viewModel.doneTitleEditing(title: textField.text ?? "")
        return true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        guard viewModel.editingMode == .title else { return }
        viewModel.doneTitleEditing(title: textField.text ?? "")
    }
}

// MARK: - Page

private extension VoiceNoteViewController {
    enum Page: Int, CaseIterable {
        case summary
        case script

        var title: String {
            switch self {
            case .summary: return "요약"
            case .script: return "스크립트"
            }
        }
    }
}
