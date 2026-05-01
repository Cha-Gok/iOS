import Core
import Domain
import SwiftUI
import UIKit

public final class MainViewController: ViewController {
    // MARK: - Type

    typealias CategoryHeaderRegistration = UICollectionView.SupplementaryRegistration<MainCategoryHeaderView>
    typealias ListCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, ContentItem>
    typealias EmptyCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, MainCellItem>
    typealias SectionHeaderRegistration = UICollectionView.SupplementaryRegistration<MainSectionHeaderView>
    typealias DataSource = UICollectionViewDiffableDataSource<MainSection, MainCellItem>
    typealias SnapShot = NSDiffableDataSourceSnapshot<MainSection, MainCellItem>

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

    private lazy var langAction: UIAction = UIAction(title: "녹음 언어 선택") { [weak self] _ in
        guard let self else { return }
        vm.alertCoordinator?.presentAlert(
            environment: .languageSelect(vm.checkLanguage()),
            delegate: self
        )
    }

    private lazy var termsofServiceAction: UIAction = UIAction(title: "약관 보기") { [weak self] _ in
    }

    private lazy var searchItem: UIBarButtonItem = {
        let search = UIBarButtonItem()
        search.image = UIImage(systemName: "magnifyingglass")
        search.menu = nil
        search.primaryAction = UIAction { [weak self] _ in
            self?.vm.pushSearchView()
        }
        return search
    }()

    private lazy var settingItem: UIBarButtonItem = .init(
        image: UIImage(systemName: "gearshape"),
        menu: UIMenu(title: "", children: [langAction, termsofServiceAction])
    )

    private let floatingButton: GlassButton = .floating(
        image: .init(imageName: "microphone", type: .system)
    )

    var dataSource: DataSource!

    // MARK: LifeCycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupCollectionView()
        setupfloatingButton()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        vm.updateRecentCategory()
        vm.updateVoiceNoteCategory()
        vm.updateMyFolderCategory()
        vm.updateTrashCategory()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        vm.cancelObservations()
    }

    override public func updateProperties() {
        super.updateProperties()
        updateNavigationBarAppearance(isTransparent: false)
        updateDataSource()
    }

    // MARK: Setup

    private func setup() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: navTitle)
        navigationItem.rightBarButtonItems = [settingItem, searchItem]
        navigationItem.leftBarButtonItem?.hidesSharedBackground = true
        navigationItem.rightBarButtonItems?.forEach { $0.hidesSharedBackground = true
        }
    }

    private func setupCollectionView() {
        view.addSubview(collectionView)
        view.addSubview(floatingButton)
        collectionViewConstraint()
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.setCollectionViewLayout(
            createLayout(),
            animated: false
        )

        let listRegistration = ListCellRegistration { cell, _, item in
            cell.backgroundConfiguration = .clear()
            cell.contentConfiguration = UIHostingConfiguration {
                switch item {
                case .folder(let data):
                    FolderCardView(folder: data)
                case .voiceNote(let data):
                    VoiceNoteCardView(
                        voiceNote: data,
                        completeAction: { [weak self] in
                            self?.vm.pushVoiceNoteView(voiceNote: data)
                        }
                    )
                }
            }
            .margins(.all, 0)
        }

        let emptyRegistration = EmptyCellRegistration { cell, _, _ in
            cell.backgroundConfiguration = .clear()
            cell.contentConfiguration = EmptyContentConfiguration(
                message: "아직 녹음된 기록이 없습니다.\n녹음 버튼을 눌러 첫 기록을 시작해보세요."
            )
        }

        let categoryHeaderRegistration = CategoryHeaderRegistration(
            elementKind: MainCategoryHeaderView.elementKind
        ) { [weak self] header, _, _ in
            guard let self else { return }
            header.configure(
                categories: vm.categoryData,
                selectedIndex: vm.selectedCategoryIndex,
                didScroll: vm.didScroll
            ) { [weak self] selectedIndex in
                self?.selectCategory(at: selectedIndex)
            }
        }

        let sectionHeaderRegistration = SectionHeaderRegistration(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { header, _, indexPath in
            guard let section = self.dataSource.sectionIdentifier(for: indexPath.section),
                  case .groupedList(let group) = section else { return }
            header.configure(title: group.title)
        }

        setupDataSource(
            listRegistration: listRegistration,
            emptyRegistration: emptyRegistration,
            categoryHeaderRegistration: categoryHeaderRegistration,
            sectionHeaderRegistration: sectionHeaderRegistration
        )
    }

    private func setupfloatingButton() {
        floatingButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            vm.handleRecordButtonTap(
                alertAction: {
                    vm.alertCoordinator?.presentAlert(environment: .micPermissionRequired, delegate: self)
                }
            )
        }, for: .touchUpInside)

        NSLayoutConstraint.activate([
            floatingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            floatingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -42)
        ])
    }

    private func collectionViewConstraint() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func updateInteractionForAlert(isPresented: Bool) {
        collectionView.isUserInteractionEnabled = !isPresented
        navigationItem.leftBarButtonItem?.isEnabled = !isPresented
        navigationItem.rightBarButtonItem?.isEnabled = !isPresented
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = !isPresented }
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsURL) else { return }
        UIApplication.shared.open(settingsURL)
    }
}

// MARK: - Collection view Layout Custom

extension MainViewController {
    private func createLayout() -> UICollectionViewCompositionalLayout {
        let sectionProvider: UICollectionViewCompositionalLayoutSectionProvider = { [weak self] sectionIndex, _ in
            guard let self,
                  let section = dataSource.sectionIdentifier(for: sectionIndex)
            else {
                return self?.emptySection()
            }

            switch section {
            case .list:
                return createSection(
                    itemWidth: .fractionalWidth(1.0),
                    itemHeight: .estimated(120),
                    groupWidth: .fractionalWidth(1.0),
                    groupHeight: .estimated(120),
                    interGroupSpacing: 8,
                    contentInsets: .init(top: 32, leading: 20, bottom: 0, trailing: 20)
                )
            case .groupedList:
                return createSection(
                    itemWidth: .fractionalWidth(1.0),
                    itemHeight: .estimated(120),
                    groupWidth: .fractionalWidth(1.0),
                    groupHeight: .estimated(120),
                    interGroupSpacing: 8,
                    contentInsets: .init(top: 0, leading: 20, bottom: 0, trailing: 20),
                    headerHeight: 72
                )
            case .emptyList:
                return createSection(
                    itemWidth: .fractionalWidth(1.0),
                    itemHeight: .estimated(300),
                    groupWidth: .fractionalWidth(1.0),
                    groupHeight: .estimated(300)
                )
            }
        }

        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        let categoryHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(120)
            ),
            elementKind: MainCategoryHeaderView.elementKind,
            alignment: .top
        )
        categoryHeader.pinToVisibleBounds = true
        categoryHeader.zIndex = 10
        configuration.boundarySupplementaryItems = [categoryHeader]

        return UICollectionViewCompositionalLayout(
            sectionProvider: sectionProvider,
            configuration: configuration
        )
    }

    private func group(for item: ContentItem, now: Date = .now) -> MainListDateGroup {
        let calendar = Calendar.current
        let date = item.createdAt

        if calendar.isDate(date, inSameDayAs: now) {
            return .today
        }

        let startOfToday = calendar.startOfDay(for: now)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: startOfToday) ?? startOfToday
        if date >= sevenDaysAgo {
            return .recentSevenDays
        }

        return .older
    }

    private func groupedItems(_ items: [ContentItem]) -> [(section: MainSection, items: [MainCellItem])] {
        let grouped = Dictionary(grouping: items) { group(for: $0) }

        return MainListDateGroup.allCases.compactMap { group in
            guard let items = grouped[group], !items.isEmpty else { return nil }
            let sortedItems = items.sorted { $0.createdAt > $1.createdAt }
            return (.groupedList(group), sortedItems.map(MainCellItem.list))
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

        if let headerHeight {
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(headerHeight)
            )
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            header.contentInsets = .init(top: 0, leading: 4, bottom: 16, trailing: 4)
            section.boundarySupplementaryItems = [header]
        }

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
    private func setupDataSource(
        listRegistration: ListCellRegistration,
        emptyRegistration: EmptyCellRegistration,
        categoryHeaderRegistration: CategoryHeaderRegistration,
        sectionHeaderRegistration: SectionHeaderRegistration
    ) {
        dataSource = UICollectionViewDiffableDataSource(
            collectionView: collectionView,
            cellProvider: { collectionView, indexPath, itemIdentifier in
                switch itemIdentifier {
                case .list(let item):
                    return collectionView.dequeueConfiguredReusableCell(
                        using: listRegistration,
                        for: indexPath,
                        item: item
                    )
                case .emptyList:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: emptyRegistration,
                        for: indexPath,
                        item: itemIdentifier
                    )
                }
            }
        )

        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            if kind == MainCategoryHeaderView.elementKind {
                return collectionView.dequeueConfiguredReusableSupplementary(
                    using: categoryHeaderRegistration,
                    for: indexPath
                )
            }

            guard kind == UICollectionView.elementKindSectionHeader else { return nil }
            return collectionView.dequeueConfiguredReusableSupplementary(
                using: sectionHeaderRegistration,
                for: indexPath
            )
        }
    }

    private func updateDataSource() {
        var snapshot = SnapShot()

        let selectedCategory = vm.categoryData[vm.selectedCategoryIndex]
        let items = selectedCategory.items
        if items.isEmpty {
            snapshot.appendSections([.emptyList])
            snapshot.appendItems([.emptyList], toSection: .emptyList)
        } else if vm.shouldGroupSelectedCategory {
            for group in groupedItems(items) {
                snapshot.appendSections([group.section])
                snapshot.appendItems(group.items, toSection: group.section)
            }
        } else {
            snapshot.appendSections([.list])
            let cellItems = items.map(MainCellItem.list)
            snapshot.appendItems(cellItems, toSection: .list)
        }

        dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
            self?.updateVisibleCategoryHeader()
        }
    }

    private func selectCategory(at index: Int) {
        vm.setSelectedCategoryIndex(indexPath: IndexPath(item: index, section: 0))
        updateDataSource()
    }

    private func updateVisibleCategoryHeader() {
        guard let header = collectionView.visibleSupplementaryViews(ofKind: MainCategoryHeaderView.elementKind)
            .first as? MainCategoryHeaderView else { return }

        header.configure(
            categories: vm.categoryData,
            selectedIndex: vm.selectedCategoryIndex,
            didScroll: vm.didScroll
        ) { [weak self] selectedIndex in
            self?.selectCategory(at: selectedIndex)
        }
    }
}

// MARK: - Delegate

extension MainViewController: UICollectionViewDelegate, ChaGokAlertButtonTappedDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        let didScroll = offsetY > 0

        guard vm.didScroll != didScroll else { return }
        vm.setDidScroll(didScroll)
        guard let header = collectionView.visibleSupplementaryViews(ofKind: MainCategoryHeaderView.elementKind)
            .first as? MainCategoryHeaderView else { return }
        header.updateScrollState(didScroll)
        collectionView.collectionViewLayout.invalidateLayout()
    }

    public func languageSelectCloseButtonTapped(_ alertVC: ChaGokAlertViewController) {
        alertVC.dismiss(animated: true)
    }

    public func languageSelectPrimaryButtonTapped(_ alertVC: ChaGokAlertViewController) {
        if let selectedLanguage = alertVC.selectedLanguage {
            vm.saveLanguage(selectedLanguage)
        }
        alertVC.dismiss(animated: true)
    }

    public func micPermissionCloseButtonTapped(_ alertVC: ChaGokAlertViewController) {
        alertVC.dismiss(animated: true)
    }

    public func micPermissionPrimaryButtonTapped(_ alertVC: ChaGokAlertViewController) {
        openAppSettings()
        alertVC.dismiss(animated: true)
    }
}

#if DEBUG
    #Preview("최근 기록") {
        UINavigationController(
            rootViewController: MainViewController(
                vm: .preview(selectedCategoryIndex: 0)
            )
        )
    }

    #Preview("기본 폴더") {
        UINavigationController(
            rootViewController: MainViewController(
                vm: .preview(selectedCategoryIndex: 1)
            )
        )
    }

    #Preview("개인 폴더") {
        UINavigationController(
            rootViewController: MainViewController(
                vm: .preview(selectedCategoryIndex: 2)
            )
        )
    }

    #Preview("휴지통") {
        UINavigationController(
            rootViewController: MainViewController(
                vm: .preview(selectedCategoryIndex: 3)
            )
        )
    }
#endif
