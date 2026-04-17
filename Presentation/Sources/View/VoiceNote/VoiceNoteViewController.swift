import Domain
import UIKit

public final class VoiceNoteViewController: UIViewController, Alertable {
    typealias Section = VoiceNoteViewModel.Section
    typealias Item = VoiceNoteViewModel.Item

    private let viewModel: VoiceNoteViewModel
    private var hasAppliedCompletedSnapshot = false
    private lazy var dataSource = makeDataSource()

    // MARK: - UI Components

    private let playerView = AudioPlayerView()
    private let topBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private lazy var segmentedControl = UnderlineSegmentedControl(items: [Section.keyPoints, .keywords, .scripts]
        .compactMap(\.title))
    private lazy var backButton: UIButton = {
        let btn = UIButton(type: .system)
        let backImage = UIImage(systemName: "chevron.left")?
            .withConfiguration(UIImage.SymbolConfiguration(weight: .bold))
        btn.setImage(backImage, for: .normal)
        btn.titleLabel?.setTypography(style: .title1)
        btn.tintColor = UIColor.gray950
        return btn
    }()

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
        viewModel.send(.view(.onAppear))
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.send(.view(.onDisappear))
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
        observePlaybackState()
        observeAnalysisState()
        observeErrorMessage()
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
        backButton.setTitle(" \(viewModel.state.title)", for: .normal)
        backButton.addAction(
            UIAction { [weak self] _ in
                self?.viewModel.send(.view(.pop))
            }, for: .touchUpInside
        )
        let menu = UIMenu(children: [
            UIAction(title: "기록 이동하기", handler: { _ in
                self.viewModel.send(.view(.moveVoiceNoteButtonTapped))
            }),
            UIAction(title: "편집하기", handler: { _ in }),
            UIAction(title: "삭제하기", attributes: .destructive, handler: { _ in
            })
        ])
        let moreItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: menu)
        let searchItem = UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass"),
            style: .plain,
            target: nil,
            action: nil
        )
        let leftItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = leftItem
        navigationItem.rightBarButtonItems = [moreItem, searchItem]
        navigationItem.rightBarButtonItems?.forEach { $0.tintColor = .white }
        navigationItem.leftBarButtonItem?.hidesSharedBackground = true
        navigationItem.rightBarButtonItems?.forEach {
            $0.hidesSharedBackground = true
        }
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
        playerView.onPlayPause = { [weak self] in self?.viewModel.send(.view(.playPauseButtonTapped)) }
        playerView.onRewind = { [weak self] in self?.viewModel.send(.view(.rewindButtonTapped)) }
        playerView.onForward = { [weak self] in self?.viewModel.send(.view(.forwardButtonTapped)) }
        playerView.onSeekBegan = { [weak self] in self?.viewModel.send(.view(.seekBegan)) }
        playerView.onSeekEnded = { [weak self] time in self?.viewModel.send(.view(.seekEnded(time))) }
    }

    private func observePlaybackState() {
        withObservationTracking {
            _ = viewModel.state.currentPlaybackState
        } onChange: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.playerView.apply(self.viewModel.state.currentPlaybackState)
                self.observePlaybackState()
            }
        }
    }

    private func observeAnalysisState() {
        withObservationTracking {
            _ = viewModel.state.voiceNote.analysisState
        } onChange: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                switch self.viewModel.state.voiceNote.analysisState {
                case .analyzing:
                    var snapshot = self.dataSource.snapshot()
                    snapshot.reconfigureItems([.metadata])
                    self.dataSource.apply(snapshot, animatingDifferences: false)
                case .completed:
                    if !self.hasAppliedCompletedSnapshot {
                        self.hasAppliedCompletedSnapshot = true
                        self.applySnapshot()
                    }
                case .failed, .pending:
                    break
                }
                self.observeAnalysisState()
            }
        }
    }

    private func observeErrorMessage() {
        withObservationTracking {
            _ = viewModel.state.errorMessage
        } onChange: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                if let message = self.viewModel.state.errorMessage {
                    self.showAlert(title: "오류", message: message) { [weak self] in
                        self?.viewModel.send(.internal(.errorDismissed))
                    }
                }
                self.observeErrorMessage()
            }
        }
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
                folderName: self?.viewModel.state.folderName ?? "",
                date: self?.viewModel.state.metadataText1 ?? "",
                duration: self?.viewModel.state.metadataText2 ?? ""
            )
        }

        let keyPointCellReg = UICollectionView.CellRegistration<UICollectionViewCell, Item> { cell, _, item in
            guard case .keyPoint(let number, let text) = item else { return }
            cell.contentConfiguration = KeyPointContentConfiguration(number: number, text: text)
        }

        let keywordsCellReg = UICollectionView.CellRegistration<KeywordsCell, Item> { [weak self] cell, _, _ in
            cell.contentConfiguration = KeywordsContentConfiguration(
                keywords: self?.viewModel.state.keywords ?? []
            )
        }

        let scriptCellReg = UICollectionView.CellRegistration<UICollectionViewCell, Item> { [weak self] cell, _, item in
            guard let self, case .script(let index) = item else { return }
            let section = viewModel.state.scriptSections[index]

            cell.contentConfiguration = ScriptContentConfiguration(
                sectionIndex: index,
                timestamp: section.formattedTimestamp,
                timestampSeconds: section.timestamp,
                paragraphs: section.paragraphs,
                highlight: viewModel.state.playbackHighlight,
                onTimestampTapped: { [weak self] time in
                    self?.viewModel.send(.view(.scriptTimestampTapped(time)))
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
        snapshot.appendItems([.metadata], toSection: .metadata)
        snapshot.appendItems(
            viewModel.state.keyPoints.map { .keyPoint(number: $0.number, text: $0.text) },
            toSection: .keyPoints
        )
        snapshot.appendItems([.keywords], toSection: .keywords)
        snapshot.appendItems(viewModel.state.scriptSections.indices.map { .script(index: $0) }, toSection: .scripts)
        snapshot.reconfigureItems([.metadata, .keywords])
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}
