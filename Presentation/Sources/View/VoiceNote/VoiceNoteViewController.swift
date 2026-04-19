import Domain
import UIKit

public final class VoiceNoteViewController: UIViewController, Alertable {
    private let viewModel: VoiceNoteViewModel
    private lazy var dataSource = makeDataSource()

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

    private var normalRightBarButtonItems: [UIBarButtonItem] = []

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
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
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backChevronButton)
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
        reconfigureScriptsOnly()
    }

    func exitEditMode() {
        titleTextField.resignFirstResponder()
        titleLabel.text = viewModel.title
        titleLabel.isHidden = false
        navigationItem.titleView = titleLabel
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

// MARK: - CollectionView Layout & DataSource

private extension VoiceNoteViewController {
    func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { sectionIndex, environment in
            var config = UICollectionLayoutListConfiguration(appearance: .plain)
            config.backgroundColor = .clear
            config.showsSeparators = false
            config.headerMode = Section(rawValue: sectionIndex) == .metadata ? .none : .supplementary

            let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)
            let topInset: CGFloat = Section(rawValue: sectionIndex) == .metadata ? 24 : 12
            section.contentInsets = NSDirectionalEdgeInsets(top: topInset, leading: 20, bottom: 32, trailing: 20)
            if Section(rawValue: sectionIndex) == .scripts { section.interGroupSpacing = 16 }
            section.boundarySupplementaryItems.forEach { $0.pinToVisibleBounds = false }
            return section
        }
    }

    func makeDataSource() -> UICollectionViewDiffableDataSource<Section, Item> {
        let metadataCellReg = UICollectionView.CellRegistration<UICollectionViewCell, Item> { [weak self] cell, _, _ in
            cell.contentConfiguration = MetadataContentConfiguration(
                folderName: self?.viewModel.folderName ?? "",
                date: self?.viewModel.metadataText1 ?? "",
                duration: self?.viewModel.metadataText2 ?? ""
            )
        }

        let keyPointCellReg = UICollectionView.CellRegistration<UICollectionViewCell, Item> { cell, _, item in
            guard case .keyPoint(let number, let text) = item else { return }
            cell.contentConfiguration = KeyPointContentConfiguration(number: number, text: text)
        }

        let keywordsCellReg = UICollectionView.CellRegistration<KeywordsCell, Item> { [weak self] cell, _, _ in
            cell.contentConfiguration = KeywordsContentConfiguration(
                keywords: self?.viewModel.keywords ?? []
            )
        }

        let scriptCellReg = UICollectionView.CellRegistration<UICollectionViewCell, Item> { [weak self] cell, _, item in
            guard let self, case .script(let index) = item else { return }
            let section = viewModel.scriptSections[index]
            let isHighlighted = viewModel.playingSectionIndex == index

            cell.contentConfiguration = ScriptContentConfiguration(
                sectionIndex: index,
                timestamp: section.formattedTimestamp,
                timestampSeconds: section.timestamp,
                text: section.text,
                isHighlighted: isHighlighted,
                isEditing: viewModel.editingMode == .script,
                onTextEdited: { [weak self] sIdx, text in
                    self?.viewModel.updateScriptSection(sectionIndex: sIdx, text: text)
                },
                onTimestampTapped: { [weak self] time in
                    self?.viewModel.scriptTimestampTapped(time)
                }
            )
        }

        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: collectionView
        ) { col, indexPath, item in
            switch item {
            case .metadata:
                return col.dequeueConfiguredReusableCell(using: metadataCellReg, for: indexPath, item: item)
            case .keyPoint:
                return col.dequeueConfiguredReusableCell(using: keyPointCellReg, for: indexPath, item: item)
            case .keywords:
                return col.dequeueConfiguredReusableCell(using: keywordsCellReg, for: indexPath, item: item)
            case .script:
                return col.dequeueConfiguredReusableCell(using: scriptCellReg, for: indexPath, item: item)
            }
        }

        let headerReg = makeHeaderRegistration()
        dataSource.supplementaryViewProvider = { col, _, indexPath in
            col.dequeueConfiguredReusableSupplementary(using: headerReg, for: indexPath)
        }

        return dataSource
    }

    func makeHeaderRegistration() -> UICollectionView.SupplementaryRegistration<VoiceNoteSectionHeaderView> {
        UICollectionView.SupplementaryRegistration<VoiceNoteSectionHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { header, _, indexPath in
            guard let section = Section(rawValue: indexPath.section),
                  let title = section.headerTitle else { return }

            if section == .keyPoints {
                let chip = ChipView(icon: UIImage(systemName: "arrow.clockwise"), text: "재생성")
                header.configure(title: title, trailingView: chip)
            } else {
                header.configure(title: title)
            }
        }
    }

    func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)

        let metadataItems: [Item] = [.metadata]
        let keyPointItems = viewModel.keyPoints.map { Item.keyPoint(number: $0.number, text: $0.text) }
        let keywordItems: [Item] = [.keywords]
        let scriptItems = viewModel.scriptSections.indices.map { Item.script(index: $0) }

        snapshot.appendItems(metadataItems, toSection: .metadata)
        snapshot.appendItems(keyPointItems, toSection: .keyPoints)
        snapshot.appendItems(keywordItems, toSection: .keywords)
        snapshot.appendItems(scriptItems, toSection: .scripts)

        // 셀 내용이나 모드(isEditing)가 바뀌었을 수 있으므로 필요한 항목들을 재구성합니다.
        snapshot.reconfigureItems(metadataItems + keywordItems + scriptItems)
        dataSource.apply(snapshot, animatingDifferences: true)
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

// MARK: - Section / Item

extension VoiceNoteViewController {
    enum Section: Int, CaseIterable {
        case metadata
        case keyPoints
        case keywords
        case scripts

        var title: String? {
            switch self {
            case .keyPoints: return "AI 요약"
            case .keywords: return "키워드"
            case .scripts: return "스크립트"
            default: return nil
            }
        }

        var headerTitle: String? {
            switch self {
            case .keyPoints: return "핵심 포인트"
            case .keywords: return "키워드"
            case .scripts: return "스크립트"
            default: return nil
            }
        }
    }

    enum Item: Hashable {
        case metadata
        case keyPoint(number: Int, text: String)
        case keywords
        case script(index: Int)
    }
}
