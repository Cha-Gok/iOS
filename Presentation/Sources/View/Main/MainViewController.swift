import Core
import SwiftUI
import UIKit

public final class MainViewController: ViewController {
    // MARK: - Type

    typealias CategoryHeaderRegistration = UICollectionView.SupplementaryRegistration<MainCategoryHeaderView>
    typealias ListCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, LibraryItem>
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

    private let cancelAlertButton: GlassButton = .close("나중에")
    private let primaryAlertButton: GlassButton = .primary("설정으로 이동")
    private let permissionAlertOverlayView: UIView = {
        let overlay = UIView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        overlay.isHidden = true
        return overlay
    }()

    private lazy var permissionAlertView: AlertView = .init(
        title: "마이크 권한이 필요해요",
        subTitle: "설정에서 마이크 권한을 \n허용해주세요.",
        closeButton: cancelAlertButton,
        primaryButton: primaryAlertButton
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
        setupPermissionAlert()
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
        let shouldShowAlert = vm.showAlert
        permissionAlertOverlayView.isHidden = !shouldShowAlert
        updateInteractionForAlert(isPresented: shouldShowAlert)
        if shouldShowAlert {
            view.bringSubviewToFront(permissionAlertOverlayView)
        }
        updateDataSource()
    }

    // MARK: Setup

    private func setup() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.gray50
        appearance.shadowColor = .clear
        appearance.backgroundEffect = nil

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

    private func setupPermissionAlert() {
        cancelAlertButton.addAction(UIAction { [weak self] _ in
            self?.vm.closeAlertView()
        }, for: .touchUpInside)

        primaryAlertButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            vm.closeAlertView()
            openAppSettings()
        }, for: .touchUpInside)

        view.addSubview(permissionAlertOverlayView)
        permissionAlertOverlayView.addSubview(permissionAlertView)
        NSLayoutConstraint.activate([
            permissionAlertOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            permissionAlertOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            permissionAlertOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            permissionAlertOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            permissionAlertView.centerXAnchor.constraint(equalTo: permissionAlertOverlayView.centerXAnchor),
            permissionAlertView.centerYAnchor.constraint(equalTo: permissionAlertOverlayView.centerYAnchor)
        ])
    }

    private func setupCollectionView() {
        view.addSubview(collectionView)
        view.addSubview(floatingButton)
        collectionViewConstraint()
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
                    VoiceNoteCardView(
                        title: data.name,
                        subTitle: data.createdAt.description
                    )
                case .voiceNote(let data):
                    VoiceNoteCardView(
                        title: data.title,
                        subTitle: Date.now.voiceNoteDay(
                            createdAt: data.createdAt,
                            updatedAt: data.updatedAt,
                            duration: data.voiceRecord.duration
                        )
                    )
                    .onTapGesture { [weak self] in
                        self?.vm.pushVoiceNoteView(voiceNote: data)
                    }
                }
            }
            .margins(.all, 0)
        }

        let emptyRegistration = EmptyCellRegistration { cell, _, _ in
            cell.backgroundConfiguration = .clear()
            cell.contentConfiguration = MainEmptyContentConfiguration()
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
            vm.handleRecordButtonTap()
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

    private func group(for item: LibraryItem, now: Date = .now) -> MainListDateGroup {
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

    private func groupedItems(_ items: [LibraryItem]) -> [(section: MainSection, items: [MainCellItem])] {
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

extension MainViewController: UICollectionViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        let didScroll = offsetY > 0

        guard vm.didScroll != didScroll else { return }
        vm.getDidScroll(didScroll)
        guard let header = collectionView.visibleSupplementaryViews(ofKind: MainCategoryHeaderView.elementKind)
            .first as? MainCategoryHeaderView else { return }
        header.updateScrollState(didScroll)
        collectionView.collectionViewLayout.invalidateLayout()
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
