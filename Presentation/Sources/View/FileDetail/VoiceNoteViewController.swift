import UIKit

public final class VoiceNoteViewController: UIViewController {
    // MARK: - Section / Item

    private enum Section: Int, CaseIterable {
        case metadata
        case keyPoints
        case keywords
        case scripts
    }

    private enum Item: Hashable {
        case metadata
        case keyPoint(id: Int, text: String)
        case keywords
        case script(index: Int)
    }

    // MARK: - Properties

    private let viewModel = FileDetailViewModel()
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    // MARK: - UI Components

    private let bgImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.gray0
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    /// 네비게이션 및 탭 영역 딤 처리 뷰
    private let topBlurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// Tab Bar
    private let tabStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let aiSummaryTabButton = createTabButton(title: "AI 요약", isSelected: true)
    private let keywordTabButton = createTabButton(title: "키워드", isSelected: false)
    private let scriptTabButton = createTabButton(title: "스크립트", isSelected: false)

    /// Main Content
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 200, right: 0)
        collectionView.verticalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 200, right: 0)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    private let playerBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.gray0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        button.setImage(UIImage(systemName: "play.fill", withConfiguration: configuration), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let rewindButton: UIButton = {
        let button = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        button.setImage(UIImage(systemName: "gobackward.15", withConfiguration: configuration), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let forwardButton: UIButton = {
        let button = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        button.setImage(UIImage(systemName: "goforward.15", withConfiguration: configuration), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let progressBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.gray100
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureDataSource()
        applySnapshot()
    }
}

// MARK: - Setup

private extension VoiceNoteViewController {
    func setupUI() {
        view.backgroundColor = UIColor.gray0

        view.addSubview(bgImageView)
        NSLayoutConstraint.activate([
            bgImageView.topAnchor.constraint(equalTo: view.topAnchor),
            bgImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bgImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        view.addSubview(collectionView)
        view.addSubview(playerBackgroundView)
        view.addSubview(progressBar)
        playerBackgroundView.addSubview(rewindButton)
        playerBackgroundView.addSubview(forwardButton)
        view.addSubview(playButton)
        view.addSubview(topBlurView)
        view.addSubview(tabStackView)

        setupConstraints()
        setupNavigationBar()
        setupTabBar()
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: tabStackView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            topBlurView.topAnchor.constraint(equalTo: view.topAnchor),
            topBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBlurView.bottomAnchor.constraint(equalTo: tabStackView.bottomAnchor),

            tabStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            tabStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabStackView.heightAnchor.constraint(equalToConstant: 42),

            playerBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            playerBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerBackgroundView.heightAnchor.constraint(equalToConstant: 136),

            progressBar.bottomAnchor.constraint(equalTo: playerBackgroundView.topAnchor),
            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 6),

            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: playerBackgroundView.centerYAnchor, constant: -10),
            playButton.widthAnchor.constraint(equalToConstant: 120),
            playButton.heightAnchor.constraint(equalToConstant: 60),

            rewindButton.trailingAnchor.constraint(equalTo: playButton.leadingAnchor, constant: -16),
            rewindButton.centerYAnchor.constraint(equalTo: playerBackgroundView.centerYAnchor, constant: -10),
            rewindButton.widthAnchor.constraint(equalToConstant: 60),
            rewindButton.heightAnchor.constraint(equalToConstant: 60),

            forwardButton.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 16),
            forwardButton.centerYAnchor.constraint(equalTo: rewindButton.centerYAnchor),
            forwardButton.widthAnchor.constraint(equalToConstant: 60),
            forwardButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    func setupNavigationBar() {
        let titleLabel = UILabel()
        titleLabel.setTypography(text: viewModel.title, style: .header2)
        titleLabel.textColor = .white
        navigationItem.titleView = titleLabel

        let moreButton = UIButton(type: .system)
        moreButton.setImage(
            UIImage(systemName: "ellipsis")?.withConfiguration(UIImage.SymbolConfiguration(weight: .medium)),
            for: .normal
        )
        moreButton.tintColor = .white
        moreButton.transform = CGAffineTransform(rotationAngle: .pi / 2)

        let searchItem = UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass")?
                .withConfiguration(UIImage.SymbolConfiguration(weight: .medium)),
            style: .plain,
            target: nil,
            action: nil
        )
        navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: moreButton), searchItem]
    }

    func setupTabBar() {
        tabStackView.addArrangedSubview(aiSummaryTabButton)
        tabStackView.addArrangedSubview(keywordTabButton)
        tabStackView.addArrangedSubview(scriptTabButton)

        for tab in [aiSummaryTabButton, keywordTabButton, scriptTabButton] {
            tab.isUserInteractionEnabled = true
            tab.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tabTapped(_:))))
        }
    }
}

// MARK: - CollectionView Layout & DataSource

private extension VoiceNoteViewController {
    func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            switch Section(rawValue: sectionIndex) {
            case .metadata: return Self.makeMetadataSection()
            case .keyPoints: return Self.makeListSection(headerHeight: 44)
            case .keywords: return Self.makeKeywordsSection()
            case .scripts: return Self.makeListSection(headerHeight: 44)
            case nil: return nil
            }
        }
    }

    static func makeMetadataSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(80)
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: itemSize,
            subitems: [NSCollectionLayoutItem(layoutSize: itemSize)]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 32, trailing: 20)
        return section
    }

    static func makeListSection(headerHeight: CGFloat) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(50)
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: itemSize,
            subitems: [NSCollectionLayoutItem(layoutSize: itemSize)]
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(headerHeight)
            ),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 6
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 32, trailing: 20)
        section.boundarySupplementaryItems = [header]
        return section
    }

    static func makeKeywordsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44)
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: itemSize,
            subitems: [NSCollectionLayoutItem(layoutSize: itemSize)]
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(44)
            ),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 32, trailing: 20)
        section.boundarySupplementaryItems = [header]
        return section
    }

    func configureDataSource() {
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
            cell.contentConfiguration = ScriptContentConfiguration(
                timestamp: section.timestamp,
                paragraphs: section.paragraphs
            )
        }

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { col, indexPath, item in
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

        configureSupplementaryProvider()
    }

    func configureSupplementaryProvider() {
        let headerReg = UICollectionView.SupplementaryRegistration<VoiceNoteSectionHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { header, _, indexPath in
            switch Section(rawValue: indexPath.section) {
            case .keyPoints:
                let chip = ChipView(icon: UIImage(systemName: "arrow.clockwise"), text: "재생성")
                header.configure(title: "핵심 포인트", trailingView: chip)
            case .keywords: header.configure(title: "키워드")
            case .scripts: header.configure(title: "스크립트")
            default: break
            }
        }
        dataSource.supplementaryViewProvider = { col, _, indexPath in
            col.dequeueConfiguredReusableSupplementary(using: headerReg, for: indexPath)
        }
    }

    func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems([.metadata], toSection: .metadata)
        snapshot.appendItems(viewModel.keyPoints.map { .keyPoint(id: $0.id, text: $0.text) }, toSection: .keyPoints)
        snapshot.appendItems([.keywords], toSection: .keywords)
        snapshot.appendItems(viewModel.scriptSections.indices.map { .script(index: $0) }, toSection: .scripts)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Tab Actions

private extension VoiceNoteViewController {
    @objc
    func tabTapped(_ gesture: UITapGestureRecognizer) {
        let tabs = [aiSummaryTabButton, keywordTabButton, scriptTabButton]
        guard let tapped = gesture.view,
              let index = tabs.firstIndex(where: { $0 === tapped }) else { return }
        updateTabSelection(index: index)
        scrollToSection(index: index)
    }

    func updateTabSelection(index: Int) {
        let tabs = [aiSummaryTabButton, keywordTabButton, scriptTabButton]
        for (idx, tab) in tabs.enumerated() {
            let isSelected = idx == index
            (tab.viewWithTag(1) as? UILabel)?.font = UIFont.systemFont(
                ofSize: 16,
                weight: isSelected ? .bold : .regular
            )
            (tab.viewWithTag(1) as? UILabel)?.textColor = isSelected ? .white : UIColor.gray600
            tab.viewWithTag(2)?.isHidden = !isSelected
        }
    }

    func scrollToSection(index: Int) {
        // section 0 = metadata, 탭 index와 섹션 offset 1 차이
        let sectionIndex = index + 1
        guard sectionIndex < Section.allCases.count else { return }
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

// MARK: - Factory Methods

private extension VoiceNoteViewController {
    static func createTabButton(title: String, isSelected: Bool) -> UIView {
        let view = UIView()

        let label = UILabel()
        label.tag = 1
        label.text = title
        label.font = UIFont.systemFont(ofSize: 16, weight: isSelected ? .bold : .regular)
        label.textColor = isSelected ? .white : UIColor.gray600
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        let indicator = UIView()
        indicator.tag = 2
        indicator.backgroundColor = UIColor.point700
        indicator.isHidden = !isSelected
        indicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(indicator)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            indicator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            indicator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            indicator.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            indicator.heightAnchor.constraint(equalToConstant: 2)
        ])
        return view
    }
}

#Preview {
    UINavigationController(rootViewController: VoiceNoteViewController())
}
