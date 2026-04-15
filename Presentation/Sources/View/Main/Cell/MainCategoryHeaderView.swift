import UIKit

final class MainCategoryHeaderView: UICollectionReusableView {
    // MARK: - Type

    typealias DataSource = UICollectionViewDiffableDataSource<Int, CategoryToggle>
    typealias SnapShot = NSDiffableDataSourceSnapshot<Int, CategoryToggle>
    static let elementKind = "MainCategoryHeaderView"
    private static let cellReuseIdentifier = "MainCategoryHeaderCell"
    private enum LayoutConstant {
        static let expandedItemSize = CGSize(width: 92, height: 120)
        static let collapsedItemHeight: CGFloat = 38
        static let collapsedMinimumWidth: CGFloat = 116
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8

        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
        view.delegate = self
        return view
    }()

    private var dataSource: DataSource!

    // MARK: - State

    private var categories: [CategoryToggle] = []
    private var selectedIndex: Int = 0
    private var didScroll: Bool = false
    private var onSelect: ((Int) -> Void)?
    private var heightConstraint: NSLayoutConstraint!

    // MARK: - Initialize

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupDataSource()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(
        categories: [CategoryToggle],
        selectedIndex: Int,
        didScroll: Bool,
        onSelect: @escaping (Int) -> Void
    ) {
        self.categories = categories
        self.selectedIndex = selectedIndex
        self.onSelect = onSelect
        updateScrollState(didScroll)
        updateDataSource()
    }

    func updateScrollState(_ val: Bool) {
        guard didScroll != val else { return }
        didScroll = val
        heightConstraint.constant = didScroll
            ? LayoutConstant.collapsedItemHeight
            : LayoutConstant.expandedItemSize.height
        updateVisibleCells()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func setupUI() {
        backgroundColor = UIColor.gray50
        addSubview(collectionView)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: Self.cellReuseIdentifier)
        heightConstraint = collectionView.heightAnchor.constraint(
            equalToConstant: LayoutConstant.expandedItemSize.height
        )

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightConstraint
        ])
    }

    private func setupDataSource() {
        createDataSource()
        updateDataSource()
    }

    private func applySelection(animated: Bool) {
        let indexPath = IndexPath(item: selectedIndex, section: 0)
        guard categories.indices.contains(selectedIndex) else { return }
        collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: [])
        updateVisibleCells()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }
}

// MARK: - DataSource

fileprivate extension MainCategoryHeaderView {
    func createDataSource() {
        dataSource = DataSource(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            guard let self else { return nil }
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: Self.cellReuseIdentifier,
                for: indexPath
            )
            cell.backgroundConfiguration = .clear()
            cell.contentConfiguration = makeContentConfiguration(
                for: item,
                isSelected: indexPath.item == selectedIndex,
                didScroll: didScroll
            )
            return cell
        }
    }

    func updateDataSource() {
        var snapshot = SnapShot()
        snapshot.appendSections([0])
        snapshot.appendItems(categories, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
            self?.applySelection(animated: false)
        }
    }
}

// MARK: - Helper

fileprivate extension MainCategoryHeaderView {
    func updateVisibleCells() {
        for visibleCell in collectionView.visibleCells {
            guard let itemIndexPath = collectionView.indexPath(for: visibleCell),
                  let item = dataSource.itemIdentifier(for: itemIndexPath)
            else { continue }

            visibleCell.contentConfiguration = makeContentConfiguration(
                for: item,
                isSelected: itemIndexPath.item == selectedIndex,
                didScroll: didScroll
            )
        }
    }

    func makeContentConfiguration(
        for category: CategoryToggle,
        isSelected: Bool,
        didScroll: Bool
    ) -> MainCategoryContentConfiguration {
        MainCategoryContentConfiguration(
            imageName: category.imageName,
            title: category.title,
            totalCount: category.items.count,
            isSelected: isSelected,
            didScroll: didScroll
        )
    }
}

// MARK: - Delegate

extension MainCategoryHeaderView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndex = indexPath.item
        applySelection(animated: true)
        onSelect?(indexPath.item)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return .init(
            width: didScroll ? LayoutConstant.collapsedMinimumWidth : LayoutConstant.expandedItemSize.width,
            height: didScroll ? LayoutConstant.collapsedItemHeight : LayoutConstant.expandedItemSize.height
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
}
