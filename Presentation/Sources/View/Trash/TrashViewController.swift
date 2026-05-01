import Domain
import SwiftUI
import UIKit

public final class TrashViewController: CollectionViewController {
    enum Section {
        case main
    }

    typealias DataSource = UICollectionViewDiffableDataSource<Section, ContentItem>
    typealias SnapShot = NSDiffableDataSourceSnapshot<Section, ContentItem>

    private var dataSource: DataSource?

    // MARK: - Component

    private lazy var backButton: NavigationItemButton = .init(
        normalItem: .init(title: " 휴지통", imageName: "chevron.left"),
        selectedItem: .init(title: "", imageName: "xmark"),
        attributedString: Typography.title1.textAttributes
    )

    private lazy var moreAndActionButton: NavigationItemButton = .init(
        normalItem: .init(imageName: "ellipsis"),
        selectedItem: .init(title: "삭제"),
        attributedString: Typography.title1.textAttributes,
        selectedForegroundColor: .danger
    )

    private lazy var searchAndMoveButton: NavigationItemButton = .init(
        normalItem: .init(imageName: "magnifyingglass"),
        selectedItem: .init(title: "복원"),
        attributedString: Typography.title1.textAttributes
    )

    private lazy var emptyTrashAction = UIAction(
        title: "휴지통 비우기",
        image: nil,
        attributes: .destructive // 강조(빨간색) 효과
    ) { [weak self] _ in
        guard let self else { return }
        vm.alertCoordinator?.presentAlert(
            environment: .deleteAllTrash, delegate: self
        )
    }

    private lazy var selectAction = UIAction(
        title: "선택하기",
        image: nil
    ) { [weak self] _ in
        self?.vm.setSelectionMode(.multiple)
    }

    private lazy var selectAllAction = UIAction(
        title: "전체 선택하기",
        image: nil
    ) { [weak self] _ in
        self?.vm.setSelectionMode(.all)
    }

    private let vm: TrashViewModel

    public init(vm: TrashViewModel) {
        self.vm = vm
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            var listConfiguration = UICollectionLayoutListConfiguration(appearance: .plain)
            listConfiguration.headerMode = .supplementary
            listConfiguration.showsSeparators = false
            listConfiguration.backgroundColor = .clear

            let section = NSCollectionLayoutSection.list(using: listConfiguration, layoutEnvironment: layoutEnvironment)
            section.contentInsets = .init(top: 12, leading: 20, bottom: 20, trailing: 20)
            section.interGroupSpacing = 8
            section.boundarySupplementaryItems.forEach { $0.pinToVisibleBounds = false }
            return section
        }
        super.init(collectionViewLayout: layout)
    }

    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - LifeCycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        collectionView.allowsSelection = false
        collectionView.showsVerticalScrollIndicator = false
        updateNavigationBarAppearance(isTransparent: false)
        setupNavigation()
        setupDataSource()
        updateDataSource()
        
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        vm.onAppear()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        vm.onDisappear()
    }

    override public func updateProperties() {
        super.updateProperties()
        // navigation item
        updateNavigationItems(vm.select)
        updateRightBarButtonMenu(vm.select)
        // dataSource
        updateDataSource(reconfigure: true)
    }

    private func setupNavigation() {
        let leftItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = leftItem

        backButton.addAction(backButtonAction(), for: .touchUpInside)
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(customView: moreAndActionButton),
            UIBarButtonItem(customView: searchAndMoveButton)
        ]
        moreAndActionButton.addAction(moreAndActionButtonAction(), for: .touchUpInside)
        searchAndMoveButton.addAction(searchAndMoveButtonAction(), for: .touchUpInside)

        updateRightBarButtonMenu(vm.select)
        navigationItem.leftBarButtonItem?.hidesSharedBackground = true
        navigationItem.rightBarButtonItems?.forEach {
            $0.hidesSharedBackground = true
        }
    }

    private func setupDataSource() {
        let headerRegistration = UICollectionView.SupplementaryRegistration<TrashHeaderCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { _, _, _ in }

        let cellRegistration = UICollectionView.CellRegistration { [weak self] (
            cell: UICollectionViewListCell,
            indexPath: IndexPath,
            itemIdentifier: ContentItem
        ) in
            guard let self else { return }
            var backgroundConfig = UIBackgroundConfiguration.listCell()
            backgroundConfig.backgroundColor = .clear
            cell.backgroundConfiguration = backgroundConfig

            switch itemIdentifier {
            case .folder(let folder):
                cell.contentConfiguration = UIHostingConfiguration {
                    TrashFolderCardView(
                        select: vm.select,
                        isSelected: vm.selectedItems.contains(.folder(folder)),
                        folder: folder
                    ) { [weak self] data, state in
                        if state {
                            self?.vm.selectItem(.folder(data))
                        } else {
                            self?.vm.deselectItem(.folder(data))
                        }
                    } completeAction: { [weak self] in
                        self?.vm.pushDetailFolder(folder)
                    }
                }
                .margins(.all, 0)
            case .voiceNote(let voiceNote):
                cell.contentConfiguration = UIHostingConfiguration {
                    TrashVoiceNoteCardView(
                        select: vm.select,
                        isSelected: vm.selectedItems.contains(.voiceNote(voiceNote)),
                        voiceNote: voiceNote
                    ) { [weak self] data, state in
                        if state {
                            self?.vm.selectItem(.voiceNote(data))
                        } else {
                            self?.vm.deselectItem(.voiceNote(data))
                        }
                    } completeAction: { [weak self] in
                        self?.vm.pushVoiceNote(voiceNote)
                    }
                }
                .margins(.all, 0)
            }
        }

        dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: { collectionView, indexPath, itemIdentifier in
                return collectionView.dequeueConfiguredReusableCell(
                    using: cellRegistration,
                    for: indexPath,
                    item: itemIdentifier
                )
            }
        )

        dataSource?.supplementaryViewProvider = { collectionView, kind, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
    }
}

// MARK: - Update Method

extension TrashViewController {
    private func updateRightBarButtonMenu(_ select: SelectionMode) {
        let menu: UIMenu = .init(
            title: "",
            children: [selectAllAction, selectAction, emptyTrashAction]
        )
        moreAndActionButton.menu = menu
    }

    private func updateNavigationItems(_ select: SelectionMode) {
        let isEditMode = (select != .none)
        for item in [backButton, moreAndActionButton, searchAndMoveButton] {
            item.isSelected = isEditMode
            item.sizeToFit()
        }
        moreAndActionButton.showsMenuAsPrimaryAction = !isEditMode
    }

    private func updateDataSource(reconfigure: Bool = false) {
        var snapshot = SnapShot()
        snapshot.appendSections([.main])
        snapshot.appendItems(vm.items)
        if reconfigure {
            snapshot.reconfigureItems(vm.items)
        }
        dataSource?.apply(snapshot, animatingDifferences: true)
    }

    func updateInteractionForAlert(isPresented: Bool) {
        collectionView.isUserInteractionEnabled = !isPresented
        backButton.isUserInteractionEnabled = !isPresented
        moreAndActionButton.isUserInteractionEnabled = !isPresented
        searchAndMoveButton.isUserInteractionEnabled = !isPresented
    }
}

// MARK: - Helper Method

private extension TrashViewController {
    func selectedItemsForBulkAction() -> [ContentItem]? {
        switch vm.select {
        case .none:
            return nil
        case .multiple, .all:
            guard !vm.selectedItems.isEmpty else {
                vm.setSelectionMode(.none)
                return nil
            }
            return vm.selectedItems
        }
    }

    func backButtonAction() -> UIAction {
        UIAction { [weak self] _ in
            guard let self else { return }
            switch vm.select {
            case .none:
                vm.didTapBack()
            case .all, .multiple:
                vm.setSelectionMode(.none)
            }
        }
    }

    func moreAndActionButtonAction() -> UIAction {
        UIAction { [weak self] _ in
            guard let self else { return }
            vm.deleteButtonTapped { [weak self] in
                guard let self else { return }
                vm.alertCoordinator?.presentAlert(
                    environment: .deleteItemsTrash,
                    delegate: self
                )
            }
        }
    }

    func searchAndMoveButtonAction() -> UIAction {
        UIAction { [weak self] _ in
            guard let self else { return }
            switch vm.select {
            case .none:
                vm.pushSearch()
            case .multiple, .all:
                guard let selectedItems = selectedItemsForBulkAction() else {
                    return
                }
                vm.restore(items: selectedItems)
                chagokBackgroundView.makeToast("원래 위치로 복원됐어요.") { [weak self] in
                    self?.vm.cancelRestore(items: selectedItems)
                }
            }
        }
    }
}

// MARK: - Delegate

extension TrashViewController: ChaGokAlertButtonTappedDelegate {
    public func deleteAllTrashCloseButtonTapped(_ alertVC: ChaGokAlertViewController) {
        alertVC.dismiss(animated: true)
    }
    
    public func deleteAllTrashPrimaryButtonTapped(_ alertVC: ChaGokAlertViewController) {
        alertVC.dismiss(animated: true) { [weak self] in
            self?.vm.deleteAll()
            self?.chagokBackgroundView.makeToast(
                type: .normal,
                "영구 삭제 되었습니다"
            )
        }
    }
    
    public func deleteItemsTrashCloseButonTapped(_ alertVC: ChaGokAlertViewController) {
        alertVC.dismiss(animated: true)
    }
    
    public func deleteItemsTrashPrimaryButonTapped(_ alertVC: ChaGokAlertViewController) {
        alertVC.dismiss(animated: true) { [weak self] in
            guard let selectedItems = self?.selectedItemsForBulkAction() else {
                return
            }
            self?.vm.delete(items: selectedItems)
            self?.chagokBackgroundView.makeToast(
                type: .normal,
                "영구 삭제 되었습니다"
            )
        }
    }
}

#if DEBUG
    #Preview {
        UINavigationController(
            rootViewController: TrashViewController(
                vm: .preview()
            )
        )
    }
#endif
