import SwiftUI
import UIKit

public final class SearchViewController: ViewController {

    // MARK: - Type

    enum Section: Hashable {
        case empty
        case emptyResult
        case result
    }

    enum Item: Hashable {
        case empty
        case emptyResult
        case result(LibraryItem)
    }

    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias SnapShot = NSDiffableDataSourceSnapshot<Section, Item>
    typealias CellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Item>
    typealias HeaderRegistration = UICollectionView.SupplementaryRegistration<SearchHeader>

    // MARK: - Component

    private let searchBar: ChagokSearchBar = .init()
    private lazy var collectionView: CollectionView = {
        let layout = UICollectionViewFlowLayout()
        let view = CollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private var dataSource: DataSource!
    private let vm: SearchViewModel

    // MARK: - Initialize

    public init(vm: SearchViewModel) {
        self.vm = vm
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - LifeCycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupSearchBar()
        setupCollectionView()
    }

    public override func updateProperties() {
        super.updateProperties()
        updateNavigationBarAppearance(isTransparent: false)
        updateDataSource()
        updateVisibleHeader()
    }

    // MARK: - SetUp

    private func setup() {
        navigationItem.titleView = searchBar
    }

    private func setupSearchBar() {
        searchBar.textField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            vm.search(searchBar.textField.text ?? "")
        }, for: .editingChanged)

        searchBar.textField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            vm.search(searchBar.textField.text ?? "")
        }, for: .editingDidEndOnExit)

        searchBar.closeButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            searchBar.textField.text = nil
            vm.clearSearch()
        }, for: .touchUpInside)
    }

    private func setupCollectionView() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        collectionView.setCollectionViewLayout(createLayout(), animated: false)

        // 셀 등록
        let emptyCellRegistration = CellRegistration { cell, _, _ in
            cell.backgroundConfiguration = .clear()
            cell.contentConfiguration = EmptyContentConfiguration(
                message: "검색 가능한 문서가 없습니다.\n지금 첫 기록을 시작해보세요."
            )
        }

        let emptyResultCellRegistration = CellRegistration { cell, _, _ in
            cell.backgroundConfiguration = .clear()
            cell.contentConfiguration = EmptyContentConfiguration(
                message: "검색 결과가 없습니다.\n다른 검색어로 검색해보세요."
            )
        }

        let resultCellRegistration = CellRegistration { cell, _, item in
            guard case .result(let libraryItem) = item else { return }
            cell.backgroundConfiguration = .clear()
            cell.contentConfiguration = UIHostingConfiguration {
                switch libraryItem {
                case .folder(let folder):
                    FolderCardView(folder: folder)
                case .voiceNote(let voiceNote):
                    VoiceNoteCardView(voiceNote: voiceNote)
                }
            }
            .margins(.all, 0)
        }

        // DataSource 설정
        dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .empty:
                return collectionView.dequeueConfiguredReusableCell(
                    using: emptyCellRegistration, for: indexPath, item: item
                )
            case .emptyResult:
                return collectionView.dequeueConfiguredReusableCell(
                    using: emptyResultCellRegistration, for: indexPath, item: item
                )
            case .result:
                return collectionView.dequeueConfiguredReusableCell(
                    using: resultCellRegistration, for: indexPath, item: item
                )
            }
        }
        
        // 전역 Header
        let headerRegistration = HeaderRegistration.init(elementKind: SearchHeader.elementKind) { [weak self] header, _, _ in
            guard let self else { return }
            header.configure(
                keyword: vm.query,
                resultCount: vm.filteredItems.count
            )
        }
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            if kind == SearchHeader.elementKind {
                return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
            }
            return nil
        }

        updateDataSource()
    }
}

// MARK: - Update Method

extension SearchViewController {
    
    private func updateDataSource() {
        var snapshot = SnapShot()

        switch vm.searchState {
        case .empty:
            snapshot.appendSections([.empty])
            snapshot.appendItems([.empty], toSection: .empty)

        case .emptyResult:
            snapshot.appendSections([.emptyResult])
            snapshot.appendItems([.emptyResult], toSection: .emptyResult)

        case .result:
            snapshot.appendSections([.result])
            let resultItems = vm.filteredItems.map(Item.result)
            snapshot.appendItems(resultItems, toSection: .result)
        }

        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func updateVisibleHeader() {
        guard let header = collectionView
            .visibleSupplementaryViews(ofKind: SearchHeader.elementKind)
            .first as? SearchHeader
        else { return }

        header.configure(
            keyword: vm.query,
            resultCount: vm.filteredItems.count
        )
    }
}

// MARK: - Layout

extension SearchViewController {
    private func createLayout() -> UICollectionViewCompositionalLayout {
        let sectionProvider: UICollectionViewCompositionalLayoutSectionProvider = { [weak self] sectionIndex, _ in
            guard let self,
                  let section = dataSource.sectionIdentifier(for: sectionIndex)
            else {
                return self?.emptySection()
            }

            switch section {
            case .empty, .emptyResult:
                return createSection(
                    itemWidth: .fractionalWidth(1.0),
                    itemHeight: .estimated(300),
                    groupWidth: .fractionalWidth(1.0),
                    groupHeight: .estimated(300)
                )
            case .result:
                return createSection(
                    itemWidth: .fractionalWidth(1.0),
                    itemHeight: .estimated(120),
                    groupWidth: .fractionalWidth(1.0),
                    groupHeight: .estimated(120),
                    interGroupSpacing: 8,
                    contentInsets: .init(top: 16, leading: 20, bottom: 0, trailing: 20)
                )
            }
        }

        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        let globalHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(44)
            ),
            elementKind: SearchHeader.elementKind,
            alignment: .top
        )
        globalHeader.contentInsets = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
        globalHeader.pinToVisibleBounds = true
        globalHeader.zIndex = 10
        configuration.boundarySupplementaryItems = [globalHeader]

        return UICollectionViewCompositionalLayout(
            sectionProvider: sectionProvider,
            configuration: configuration
        )
    }

    private func createSection(
        itemWidth: NSCollectionLayoutDimension,
        itemHeight: NSCollectionLayoutDimension,
        groupWidth: NSCollectionLayoutDimension,
        groupHeight: NSCollectionLayoutDimension,
        interGroupSpacing: CGFloat = 0.0,
        contentInsets: NSDirectionalEdgeInsets = .zero
    ) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: itemHeight)
        let groupSize = NSCollectionLayoutSize(widthDimension: groupWidth, heightDimension: groupHeight)
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = interGroupSpacing
        section.contentInsets = contentInsets
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

#Preview {
    UINavigationController(
        rootViewController: SearchViewController(vm: SearchViewModel())
    )
}
