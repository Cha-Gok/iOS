import UIKit

final class MainCategoryHeaderView: UICollectionReusableView {
    static let elementKind = "MainCategoryHeaderView"
    private static let cellReuseIdentifier = "MainCategoryHeaderCell"
    private enum LayoutConstant {
        static let expandedItemSize = CGSize(width: 92, height: 120)
        static let collapsedItemHeight: CGFloat = 38
        static let collapsedMinimumWidth: CGFloat = 92
        static let collapsedHorizontalPadding: CGFloat = 54
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

    private lazy var dataSource = UICollectionViewDiffableDataSource<Int, CategoryToggle>(
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

    private var categories: [CategoryToggle] = []
    private var selectedIndex: Int = 0
    private var didScroll: Bool = false
    private var onSelect: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
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
        var snapshot = NSDiffableDataSourceSnapshot<Int, CategoryToggle>()
        snapshot.appendSections([0])
        snapshot.appendItems(categories, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
            self?.applySelection(animated: false)
        }
    }

    func updateScrollState(_ val: Bool) {
        guard didScroll != val else { return }
        didScroll = val
        updateVisibleCells()
    }

    private func setupUI() {
        backgroundColor = UIColor.gray50
        addSubview(collectionView)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: Self.cellReuseIdentifier)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func applySelection(animated: Bool) {
        let indexPath = IndexPath(item: selectedIndex, section: 0)
        guard categories.indices.contains(selectedIndex) else { return }

        collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: [])
        updateVisibleCells()
    }

    private func updateVisibleCells() {
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

    private func makeContentConfiguration(
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

    override func prepareForReuse() {
        super.prepareForReuse()
    }
}

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
        guard categories.indices.contains(indexPath.item) else {
            return didScroll
                ? CGSize(width: LayoutConstant.collapsedMinimumWidth, height: LayoutConstant.collapsedItemHeight)
                : LayoutConstant.expandedItemSize
        }

        if didScroll {
            return CGSize(
                width: pillWidth(for: categories[indexPath.item]),
                height: LayoutConstant.collapsedItemHeight
            )
        }

        return LayoutConstant.expandedItemSize
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }

    private func pillWidth(for category: CategoryToggle) -> CGFloat {
        let titleWidth = ceil((category.title as NSString).size(withAttributes: [
            .font: Typography.subtitle2.font
        ]).width)

        return max(LayoutConstant.collapsedMinimumWidth, titleWidth + LayoutConstant.collapsedHorizontalPadding)
    }
}
