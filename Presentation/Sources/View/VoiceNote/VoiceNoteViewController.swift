import Domain
import SwiftUI
import UIKit

public final class VoiceNoteViewController: UIViewController, Alertable {
    let viewModel: VoiceNoteViewModel

    // MARK: - UI Components

    private let playerView = AudioPlayerView()
    private lazy var segmentedControl = UnderlineSegmentedControl(items: Page.allCases.map(\.title))

    private lazy var titleLabel: TypographyLabel = {
        let label = TypographyLabel(typography: .title1)
        label.textColor = UIColor.gray950
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(titleLabelTapped))
        label.addGestureRecognizer(tap)
        return label
    }()

    private lazy var titleField: TypographyTextField = {
        let field = TypographyTextField(typography: .title1)
        field.textColor = UIColor.gray950
        field.tintColor = UIColor.gray950
        field.returnKeyType = .done
        field.delegate = self
        field.isHidden = true
        return field
    }()

    private let titleContainerView = ExpandingTitleView()

    @objc
    private func titleLabelTapped() {
        viewModel.enterTitleEditing()
    }

    private lazy var backBarButton: UIBarButtonItem = .init(
        image: UIImage(systemName: "chevron.left")?
            .withConfiguration(UIImage.SymbolConfiguration(weight: .bold)),
        primaryAction: UIAction { [weak self] _ in
            self?.viewModel.pop()
        }
    )

    private lazy var editCancelButton: UIBarButtonItem = {
        let item = UIBarButtonItem(
            image: .cornerUpLeft,
            primaryAction: UIAction { [weak self] _ in
                self?.viewModel.cancelEditing()
            }
        )
        item.hidesSharedBackground = true
        return item
    }()

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
        item.hidesSharedBackground = true
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
        for subview in [pageViewController.view!, playerView, segmentedControl] {
            subview.translatesAutoresizingMaskIntoConstraints = false
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
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    func setupTitleContainerView() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleField.translatesAutoresizingMaskIntoConstraints = false

        titleContainerView.addSubview(titleLabel)
        titleContainerView.addSubview(titleField)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: titleContainerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: titleContainerView.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: titleContainerView.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: titleContainerView.bottomAnchor),

            titleField.leadingAnchor.constraint(equalTo: titleContainerView.leadingAnchor),
            titleField.trailingAnchor.constraint(equalTo: titleContainerView.trailingAnchor),
            titleField.topAnchor.constraint(equalTo: titleContainerView.topAnchor),
            titleField.bottomAnchor.constraint(equalTo: titleContainerView.bottomAnchor),
        ])
    }

    func setupNavigationBar() {
        backBarButton.tintColor = UIColor.gray950
        setupTitleContainerView()
        titleLabel.text = viewModel.title
        titleField.text = viewModel.title
        let menu = UIMenu(children: [
            UIAction(title: "기록 이동하기", handler: { [weak self] _ in
                self?.viewModel.moveVoiceNote()
            }),
            UIAction(title: "편집하기", handler: { [weak self] _ in
                self?.viewModel.enterScriptEditing()
            }),
            UIAction(title: "삭제하기", attributes: .destructive, handler: { [weak self] _ in
                self?.viewModel.deleteVoiceNote()
            }),
        ])
        let moreItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: menu)
        let searchItem = UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass"),
            style: .plain,
            target: nil,
            action: nil
        )
        normalRightBarButtonItems = [moreItem, searchItem]
        normalLeftBarButtonItem = backBarButton
        navigationItem.leftBarButtonItem = normalLeftBarButtonItem
        navigationItem.titleView = titleContainerView
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
                self.applyEditingMode(self.viewModel.editingMode)
                self.observeScriptEdits()
            }
        }
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
            titleField.text = viewModel.title
            titleLabel.isHidden = true
            titleField.isHidden = false
            navigationItem.rightBarButtonItems = [doneButton]
            titleField.becomeFirstResponder()
        case .script:
            titleContainerView.isHidden = true
            navigationItem.leftBarButtonItem = editCancelButton
            navigationItem.rightBarButtonItems = [doneButton]
            editCancelButton.tintColor = viewModel.hasScriptEdits ? UIColor.gray950 : UIColor.gray600
            switchToPage(at: Page.script.rawValue, animated: true)
            syncSegmentedControl(to: Page.script.rawValue)
        case nil:
            titleField.resignFirstResponder()
            titleLabel.text = viewModel.title
            titleLabel.isHidden = false
            titleField.isHidden = true
            titleContainerView.isHidden = false
            navigationItem.leftBarButtonItem = normalLeftBarButtonItem
            navigationItem.rightBarButtonItems = normalRightBarButtonItems
            navigationItem.rightBarButtonItems?.forEach { $0.tintColor = .white }
        }
    }
}

// MARK: - UITextFieldDelegate

extension VoiceNoteViewController: UITextFieldDelegate {
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if viewModel.editingMode == nil {
            viewModel.enterTitleEditing()
        }
        return true
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

// MARK: - ExpandingTitleView

/// intrinsicContentSize의 width를 최대로 반환하여
/// 네비게이션 바에서 좌측~우측 아이템 사이 전체를 채우는 컨테이너 뷰.
private final class ExpandingTitleView: UIView {
    override var intrinsicContentSize: CGSize {
        let height = subviews.first(where: { !$0.isHidden })?.intrinsicContentSize.height
            ?? super.intrinsicContentSize.height
        return CGSize(width: UIView.layoutFittingExpandedSize.width, height: height)
    }
}

#if DEBUG
    #Preview("보이스 노트") {
        UINavigationController(
            rootViewController: VoiceNoteViewController(viewModel: .preview())
        )
    }
#endif
