import Domain
import UIKit

public final class VoiceNoteViewController: UIViewController, Alertable {
    let viewModel: VoiceNoteViewModel
    lazy var dataSource = makeDataSource()

    // MARK: - UI Components

    private let playerView = AudioPlayerView()
    private let topBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private lazy var segmentedControl = UnderlineSegmentedControl(items: [Section.keyPoints, .keywords, .scripts]
        .compactMap(\.title))
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

    private lazy var editCancelButton: UIBarButtonItem = {
        let item = UIBarButtonItem(image: .cornerUpLeft, primaryAction: UIAction { [weak self] _ in
            self?.viewModel.cancelEditing()
        })
        return item
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.title1.font
        label.textColor = UIColor.gray950
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(titleLabelTapped))
        label.addGestureRecognizer(tap)
        return label
    }()

    @objc
    private func titleLabelTapped() {
        viewModel.enterTitleEditing()
    }

    private lazy var titleTextField: UITextField = {
        let field = UITextField()
        field.font = Typography.title1.font
        field.textColor = UIColor.gray950
        field.tintColor = UIColor.gray950
        field.returnKeyType = .done
        field.delegate = self
        return field
    }()

    private lazy var doneButton: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "완료", primaryAction: UIAction { [weak self] _ in
            guard let self else { return }
            switch viewModel.editingMode {
            case .title:
                viewModel.doneTitleEditing(title: titleTextField.text ?? "")
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

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.keyboardDismissMode = .interactive
        return collectionView
    }()

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
        applySnapshot()
        registerKeyboardObservers()
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

        view.addSubview(collectionView)
        view.addSubview(playerView)
        view.addSubview(topBlurView)
        view.addSubview(segmentedControl)

        setupConstraints()
        setupNavigationBar()
        setupTabBar()
        setupPlayerView()
        setupBindings()
    }

    func setupConstraints() {
        for subview in [collectionView, playerView, topBlurView, segmentedControl] {
            subview.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: playerView.topAnchor),

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
        titleLabel.text = viewModel.title
        titleLabel.frame.size.width = view.bounds.width
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
        navigationItem.titleView = titleLabel
        navigationItem.rightBarButtonItems = normalRightBarButtonItems
        navigationItem.rightBarButtonItems?.forEach { $0.tintColor = .white }
        navigationItem.leftBarButtonItem?.hidesSharedBackground = true
        navigationItem.rightBarButtonItems?.forEach { $0.hidesSharedBackground = true }
    }

    func setupTabBar() {
        segmentedControl.addAction(UIAction { [weak self] action in
            guard let self, let sender = action.sender as? UnderlineSegmentedControl else { return }
            let sections: [Section] = [.keyPoints, .keywords, .scripts]
            let index = sender.selectedSegmentIndex
            guard index < sections.count else { return }
            let section = sections[index]
            scrollToSection(section: section)
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
        observeAnalysisState()
        observeErrorMessage()
        observeEditingState()
        observePlayingParagraph()
        observeScriptEdits()
    }

    private func observeScriptEdits() {
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

    private func updateEditCancelButtonTint() {
        editCancelButton.tintColor = viewModel.hasScriptEdits ? UIColor.gray950 : UIColor.gray600
    }

    private func observePlayingParagraph() {
        withObservationTracking {
            _ = viewModel.playingSectionIndex
        } onChange: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                let scriptItems = self.dataSource.snapshot().itemIdentifiers(inSection: .scripts)
                if !scriptItems.isEmpty {
                    var snapshot = self.dataSource.snapshot()
                    snapshot.reconfigureItems(scriptItems)
                    self.dataSource.apply(snapshot, animatingDifferences: false)
                }
                self.observePlayingParagraph()
            }
        }
    }

    private func observePlaybackState() {
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

    private func observeAnalysisState() {
        withObservationTracking {
            _ = viewModel.voiceNote.analysisState
        } onChange: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                switch self.viewModel.voiceNote.analysisState {
                case .analyzing:
                    var snapshot = self.dataSource.snapshot()
                    snapshot.reconfigureItems([.metadata])
                    self.dataSource.apply(snapshot, animatingDifferences: false)
                case .completed, .transcribed:
                    self.applySnapshot()
                case .failed, .pending:
                    break
                }
                self.observeAnalysisState()
            }
        }
    }

    private func observeErrorMessage() {
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
        titleTextField.text = viewModel.title
        titleTextField.frame.size.width = view.bounds.width
        navigationItem.titleView = titleTextField
        titleLabel.isHidden = true
        navigationItem.rightBarButtonItems = [doneButton]
        titleTextField.becomeFirstResponder()
        titleTextField.selectAll(nil)
    }

    func enterScriptEditMode() {
        navigationItem.titleView = nil
        navigationItem.leftBarButtonItem = editCancelButton
        navigationItem.rightBarButtonItems = [doneButton]
        updateEditCancelButtonTint()
        reconfigureScriptsOnly()
    }

    func exitEditMode() {
        titleTextField.resignFirstResponder()
        titleLabel.text = viewModel.title
        titleLabel.isHidden = false
        navigationItem.titleView = titleLabel
        navigationItem.leftBarButtonItem = normalLeftBarButtonItem
        navigationItem.rightBarButtonItems = normalRightBarButtonItems
        navigationItem.rightBarButtonItems?.forEach { $0.tintColor = .white }
        reconfigureScriptsOnly()
    }

    func reconfigureScriptsOnly() {
        var snapshot = dataSource.snapshot()
        let scriptItems = snapshot.itemIdentifiers(inSection: .scripts)
        guard !scriptItems.isEmpty else { return }
        snapshot.reconfigureItems(scriptItems)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Keyboard

private extension VoiceNoteViewController {
    func registerKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
}

extension VoiceNoteViewController {
    @objc
    fileprivate func keyboardWillChangeFrame(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = view.convert(frameValue.cgRectValue, from: nil)
        let overlap = max(0, collectionView.frame.maxY - keyboardFrame.minY)
        applyKeyboardInset(overlap, userInfo: userInfo)
        scrollActiveResponderVisible()
    }

    @objc
    fileprivate func keyboardWillHide(_ notification: Notification) {
        applyKeyboardInset(0, userInfo: notification.userInfo)
    }

    private func applyKeyboardInset(_ bottom: CGFloat, userInfo: [AnyHashable: Any]?) {
        let duration = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.25
        let curveRaw = (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt)
            ?? UInt(UIView.AnimationCurve.easeInOut.rawValue)
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.collectionView.contentInset.bottom = bottom
            self.collectionView.verticalScrollIndicatorInsets.bottom = bottom
        }
    }

    private func scrollActiveResponderVisible() {
        guard let responder = collectionView.activeFirstResponder() else { return }
        let frameInCollection = responder.convert(responder.bounds, to: collectionView)
        collectionView.scrollRectToVisible(frameInCollection.insetBy(dx: 0, dy: -16), animated: true)
    }
}

private extension UIView {
    func activeFirstResponder() -> UIView? {
        if isFirstResponder { return self }
        for subview in subviews {
            if let found = subview.activeFirstResponder() { return found }
        }
        return nil
    }
}

// MARK: - Tab Actions

private extension VoiceNoteViewController {
    func scrollToSection(section: Section) {
        let sectionIndex = section.rawValue
        let headerIndexPath = IndexPath(item: 0, section: sectionIndex)

        if let attributes = collectionView.collectionViewLayout.layoutAttributesForSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            at: headerIndexPath
        ) {
            let offsetY = max(
                -collectionView.adjustedContentInset.top,
                attributes.frame.minY - collectionView.adjustedContentInset.top
            )
            collectionView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: true)
            return
        }

        collectionView.scrollToItem(at: headerIndexPath, at: .top, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension VoiceNoteViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        viewModel.doneTitleEditing(title: textField.text ?? "")
        return true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        guard viewModel.editingMode == .title else { return }
        viewModel.doneTitleEditing(title: textField.text ?? "")
    }
}
