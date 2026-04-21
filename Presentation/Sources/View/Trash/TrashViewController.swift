import Domain
import SwiftUI
import UIKit

public final class TrashViewController: CollectionViewController {
    enum Section {
        case main
    }

    typealias DataSource = UICollectionViewDiffableDataSource<Section, LibraryItem>
    typealias SnapShot = NSDiffableDataSourceSnapshot<Section, LibraryItem>

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

    private let alertOverlayView: UIView = {
        let overlay = UIView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        overlay.isHidden = true
        return overlay
    }()

    private lazy var emptyTrashAction = UIAction(
        title: "휴지통 비우기",
        image: nil,
        attributes: .destructive // 강조(빨간색) 효과
    ) { _ in
        self.vm.openTrashAlert()
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

    private lazy var cancelButton: GlassButton = {
        let cancel = GlassButton.close("취소")
        cancel.addAction(UIAction { [weak self] _ in
            self?.vm.closeTrashAlert()
        }, for: .touchUpInside)
        return cancel
    }()

    private lazy var primaryButton: GlassButton = {
        let primary = GlassButton.danger("비우기")
        primary.addAction(UIAction { [weak self] _ in
            self?.vm.deleteAll()
            self?.vm.closeTrashAlert()
        }, for: .touchUpInside)
        return primary
    }()

    private lazy var alert: AlertView = .init(
        title: "휴지통 비울까요?",
        subTitle: "모든 파일이 영구 삭제되며\n되돌릴 수 없어요",
        closeButton: cancelButton,
        primaryButton: primaryButton
    )

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
        setupNavigation()
        setupDataSource()
        updateDataSource()
        setupAlertView()
        updateNavigationBarAppearance(isTransparent: vm.showTrashAlert)
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        vm.fetchItems()
    }

    override public func updateProperties() {
        super.updateProperties()
        // navigation item
        updateNavigationItems(vm.select)
        updateRightBarButtonMenu(vm.select)
        // dataSource
        updateDataSource(reconfigure: true)
        // alert
        updateAlertState()
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
            itemIdentifier: LibraryItem
        ) in
            guard let self else { return }
            var backgroundConfig = UIBackgroundConfiguration.listCell()
            backgroundConfig.backgroundColor = .clear
            cell.backgroundConfiguration = backgroundConfig
            
            switch itemIdentifier {
            case .folder(let folder):
                cell.contentConfiguration = UIHostingConfiguration {
                    FolderCardView(
                        select: vm.select,
                        isSelected: vm.selectedItems.contains(.folder(obj: folder)),
                        folder: folder
                    ) { [weak self] data, state in
                        if state {
                            self?.vm.selectItem(.folder(obj: data))
                        } else {
                            self?.vm.deselectItem(.folder(obj: data))
                        }
                    } completeAction: { [weak self] in
                        self?.vm.pushDetailFolder(folder)
                    }
                }
                .margins(.all, 0)
            case .voiceNote(let voiceNote):
                cell.contentConfiguration = UIHostingConfiguration {
                    VoiceNoteCardView(
                        select: vm.select,
                        isSelected: vm.selectedItems.contains(.voiceNote(obj: voiceNote)),
                        voiceNote: voiceNote
                    ) { [weak self] data, state in
                        if state {
                            self?.vm.selectItem(.voiceNote(obj: data))
                        } else {
                            self?.vm.deselectItem(.voiceNote(obj: data))
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

    private func setupAlertView() {
        view.addSubview(alertOverlayView)
        alertOverlayView.addSubview(alert)
        NSLayoutConstraint.activate([
            alertOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            alertOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            alertOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            alertOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            alert.centerXAnchor.constraint(equalTo: alertOverlayView.centerXAnchor),
            alert.centerYAnchor.constraint(equalTo: alertOverlayView.centerYAnchor)
        ])
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

    private func updateAlertState() {
        let shouldShowAlert = vm.showTrashAlert
        alertOverlayView.isHidden = !shouldShowAlert
        updateInteractionForAlert(isPresented: shouldShowAlert)
        if shouldShowAlert {
            view.bringSubviewToFront(alertOverlayView)
        }
        updateNavigationBarAppearance(isTransparent: shouldShowAlert)
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
            switch vm.select {
            case .multiple:
                guard !vm.selectedItems.isEmpty else {
                    vm.setSelectionMode(.none)
                    return
                }
                vm.delete(items: vm.selectedItems)
                chagokBackgroundView.makeToast(
                    type: .normal,
                    "삭제되었습니다"
                )
            default:
                break
            }
        }
    }

    func searchAndMoveButtonAction() -> UIAction {
        UIAction { [weak self] _ in
            guard let self else { return }
            switch vm.select {
            case .none:
                print("검색 버튼 탭됨")
            case .multiple, .all:
                guard !vm.selectedItems.isEmpty else {
                    vm.setSelectionMode(.none)
                    return
                }
                let restoredItems = vm.selectedItems
                vm.restore(items: vm.selectedItems)
                chagokBackgroundView.makeToast("원래 위치로 복원됐어요.") { [weak self] in
                    self?.vm.cancelRestore(items: restoredItems)
                }
            }
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
