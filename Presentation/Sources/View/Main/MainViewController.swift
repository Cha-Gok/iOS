import UIKit

public final class MainViewController: ViewController {
    // MARK: - View Model

    private let vm: MainViewModel

    // MARK: - Initialize

    public init(vm: MainViewModel) {
        self.vm = vm
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - Component

    private let navTitle: UILabel = {
        let n = UILabel()
        n.translatesAutoresizingMaskIntoConstraints = false
        n.setTypography(text: "차곡", style: .header2)
        n.textColor = UIColor.gray950
        return n
    }()

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let c = UICollectionView(frame: .zero, collectionViewLayout: layout)
        c.translatesAutoresizingMaskIntoConstraints = false
        c.backgroundColor = .clear
        return c
    }()

    private let floatingButton: GlassButton = .floating(
        image: .init(imageName: "microphone", type: .system)
    )

    var dataSource: UICollectionViewDiffableDataSource<MainSection, MainCellItem>!

    // MARK: LifeCycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupCollectionView()
        floatingButtonConstraint()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        vm.updateRecentCategory()
        vm.updateVoiceNoteCategory()
        vm.updateMyFolderCategory()
        vm.updateTrashCategory()
    }

    override public func updateProperties() {
        super.updateProperties()
        updateDataSource()
    }

    // MARK: Setup

    private func setup() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.gray50
        appearance.shadowColor = .clear

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: navTitle)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass"),
            menu: nil
        )
        navigationItem.leftBarButtonItem?.hidesSharedBackground = true
        navigationItem.rightBarButtonItem?.hidesSharedBackground = true
    }

    private func setupCollectionView() {
        view.addSubview(collectionView)
        view.addSubview(floatingButton)
        collectionViewConstraint()

        collectionView.register(
            MainCategoryViewCell.self,
            forCellWithReuseIdentifier: MainCategoryViewCell.reuseIdentifier
        )
        collectionView.register(
            MainViewListCell.self,
            forCellWithReuseIdentifier: MainViewListCell.reuseIdentifier
        )
        collectionView.register(
            MainEmptyListCell.self,
            forCellWithReuseIdentifier: MainEmptyListCell.reuseIdentifier
        )
        collectionView.setCollectionViewLayout(
            createLayout(),
            animated: false
        )
        collectionView.delegate = self
        setupDataSource()
    }

    private func collectionViewConstraint() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func floatingButtonConstraint() {
        floatingButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            vm.presentRecodingView()
        }, for: .touchUpInside)

        NSLayoutConstraint.activate([
            floatingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            floatingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
}

// MARK: - Collection view Layout Custom

extension MainViewController {
    private func createLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self else { return self?.emptySection() }
            let section = dataSource.sectionIdentifier(for: sectionIndex)
            switch section {
            case .category:
                return createSection(
                    itemWidth: .fractionalWidth(1.0),
                    itemHeight: .absolute(120),
                    groupWidth: .absolute(92),
                    groupHeight: .absolute(120),
                    interGroupSpacing: 8,
                    contentInsets: .init(top: 0, leading: 20, bottom: 0, trailing: 20),
                    scrollBehavior: .continuous
                )
            case .list:
                if vm.isEmptyList {
                    return createSection(
                        itemWidth: .fractionalWidth(1.0),
                        itemHeight: .estimated(300),
                        groupWidth: .fractionalWidth(1.0),
                        groupHeight: .estimated(300)
                    )
                } else {
                    return createSection(
                        itemWidth: .fractionalWidth(1.0),
                        itemHeight: .absolute(80),
                        groupWidth: .fractionalWidth(1.0),
                        groupHeight: .absolute(80),
                        interGroupSpacing: 10,
                        contentInsets: .init(top: 32, leading: 20, bottom: 20, trailing: 20)
                    )
                }
            default: return emptySection()
            }
        }
    }

    private func createSection(
        itemWidth: NSCollectionLayoutDimension,
        itemHeight: NSCollectionLayoutDimension,
        groupWidth: NSCollectionLayoutDimension,
        groupHeight: NSCollectionLayoutDimension,
        interItemSpacing: NSCollectionLayoutSpacing = .fixed(0),
        interGroupSpacing: CGFloat = 0.0,
        contentInsets: NSDirectionalEdgeInsets = .zero,
        headerHeight: CGFloat? = nil,
        scrollBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior = .none
    ) -> NSCollectionLayoutSection {
        let itemSize: NSCollectionLayoutSize = .init(
            widthDimension: itemWidth, heightDimension: itemHeight
        )
        let groupSize: NSCollectionLayoutSize = .init(
            widthDimension: groupWidth, heightDimension: groupHeight
        )

        let item: NSCollectionLayoutItem = .init(layoutSize: itemSize)
        let group: NSCollectionLayoutGroup = .vertical(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = interItemSpacing
        let section: NSCollectionLayoutSection = .init(group: group)
        section.interGroupSpacing = interGroupSpacing
        section.contentInsets = contentInsets
        section.orthogonalScrollingBehavior = scrollBehavior
        // Header Content 추가

        return section
    }

    private func emptySection() -> NSCollectionLayoutSection {
        createSection(
            itemWidth: .fractionalWidth(0),
            itemHeight: .fractionalHeight(0),
            groupWidth: .fractionalWidth(0),
            groupHeight: .fractionalHeight(0)
        )
    }
}

// MARK: - setup DataSource

extension MainViewController {
    private func setupDataSource() {
        createDataSource()
    }

    private func createDataSource() {
        dataSource = UICollectionViewDiffableDataSource(
            collectionView: collectionView,
            cellProvider: { collectionView, indexPath, itemIdentifier in
                switch itemIdentifier {
                case .category(let categoryToggle):
                    let cell =
                        collectionView.dequeueReusableCell(
                            withReuseIdentifier: MainCategoryViewCell.reuseIdentifier,
                            for: indexPath
                        ) as! MainCategoryViewCell
                    cell.configure(
                        imageName: categoryToggle.imageName,
                        title: categoryToggle.title,
                        totalCount: categoryToggle.items.count
                    )
                    return cell
                case .list(let libraryItem):
                    let cell =
                        collectionView.dequeueReusableCell(
                            withReuseIdentifier: MainViewListCell.reuseIdentifier,
                            for: indexPath
                        ) as! MainViewListCell

                    cell.configure(libraryItem: libraryItem)
                    return cell
                case .emptyList:
                    return collectionView.dequeueReusableCell(
                        withReuseIdentifier: MainEmptyListCell.reuseIdentifier,
                        for: indexPath
                    )
                }
            }
        )
    }

    private func updateDataSource() {
        var snapshot = NSDiffableDataSourceSnapshot<MainSection, MainCellItem>()

        // 1. 카테고리 섹션
        let categorySection = MainSection.category
        snapshot.appendSections([categorySection])
        let categoryItems = vm.categoryData.map { MainCellItem.category($0) }
        snapshot.appendItems(categoryItems, toSection: categorySection)

        // 2. 리스트 섹션
        let listSection = MainSection.list
        snapshot.appendSections([listSection])

        let items = vm.categoryData[vm.selectedCategoryIndex].items
        if items.isEmpty {
            snapshot.appendItems([.emptyList], toSection: listSection)
        } else {
            let cellItems = items.map { MainCellItem.list($0) }
            snapshot.appendItems(cellItems, toSection: listSection)
        }

        dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
            guard let self else { return }
            let indexPath = IndexPath(item: vm.selectedCategoryIndex, section: 0)
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }
    }
}

// MARK: - CollectionView Delegate

extension MainViewController: UICollectionViewDelegate {
    public func collectionView(
        _ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath
    ) -> Bool {
        let section = dataSource.sectionIdentifier(for: indexPath.section)
        // 카테고리 섹션만 선택 가능하도록 제한하여, 리스트 클릭 시 카테고리 선택이 풀리지 않게 합니다.
        return section == .category
    }

    public func collectionView(
        _ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath
    ) {
        let section = dataSource.sectionIdentifier(for: indexPath.section)
        guard case .category = section else { return }
        vm.setSelectedCategoryIndex(indexPath: indexPath)
        collectionView.setCollectionViewLayout(createLayout(), animated: false)
        updateDataSource()
    }
}
