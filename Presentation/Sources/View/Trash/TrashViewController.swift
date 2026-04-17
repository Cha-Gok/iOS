import Domain
import SwiftUI
import UIKit

public final class TrashViewController: UICollectionViewController {
    enum Section {
        case main
    }

    typealias DataSource = UICollectionViewDiffableDataSource<Section, LibraryItem>
    typealias SnapShot = NSDiffableDataSourceSnapshot<Section, LibraryItem>

    private var dataSource: DataSource?

    private lazy var backButton: UIButton = {
        let btn = UIButton(type: .system)
        let backImage = UIImage(systemName: "chevron.left")?
            .withConfiguration(UIImage.SymbolConfiguration(weight: .bold))
        btn.setImage(backImage, for: .normal)
        btn.setTitle("휴지통", for: .normal)
        btn.titleLabel?.setTypography(style: .title1)
        btn.tintColor = UIColor.gray950
        return btn
    }()

    // MARK: - Component

    private lazy var createdAtAction = UIAction(
        title: "생성일 순"
    ) { _ in
        self.vm.touchCreatedAction()
    }

    private lazy var updatedAtAction = UIAction(
        title: "수정일 순"
    ) { _ in
        self.vm.touchUpdatedAction()
    }

    private lazy var emptyTrashAction = UIAction(
        title: "휴지통 비우기",
        image: UIImage(systemName: "trash"),
        attributes: .destructive // 강조(빨간색) 효과
    ) { _ in
        self.vm.toggleShowAlert()
    }

    private lazy var selectAction = UIAction(
        title: vm.isSelectionMode ? "완료" : "선택하기",
        image: UIImage(systemName: "checkmark.circle")
    ) { [weak self] _ in
        self?.vm.toggleSelectionMode()
    }

    private lazy var cancelButton: GlassButton = {
        let cancel = GlassButton.close("취소")
        cancel.addAction(UIAction { [weak self] _ in
            self?.vm.toggleShowAlert()
        }, for: .touchUpInside)
        return cancel
    }()

    private lazy var primaryButton: GlassButton = {
        let primary = GlassButton.danger("비우기")
        primary.addAction(UIAction { [weak self] _ in
            self?.vm.deleteAll()
            self?.vm.toggleShowAlert()
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
            listConfiguration.backgroundColor = .gray50

            let section = NSCollectionLayoutSection.list(using: listConfiguration, layoutEnvironment: layoutEnvironment)
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
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        vm.fetchItems()
    }

    override public func updateProperties() {
        super.updateProperties()
        // menu
        switch vm.selectedOrder {
        case .createdAt:
            createdAtAction.image = UIImage(systemName: "checkmark")
            updatedAtAction.image = nil
        case .updatedAt:
            createdAtAction.image = nil
            updatedAtAction.image = UIImage(systemName: "checkmark")
        }
        selectAction.title = vm.isSelectionMode ? "완료" : "선택하기"
        // dataSource
        collectionView.allowsMultipleSelection = vm.isSelectionMode
        if !vm.isSelectionMode {
            collectionView.indexPathsForSelectedItems?.forEach {
                collectionView.deselectItem(at: $0, animated: false)
            }
        }
        updateDataSource(reconfigure: true)
        updateRightBarButtonMenu()
        // alert
        alert.isHidden = !vm.showAlert
    }

    private func updateRightBarButtonMenu() {
        let menu = UIMenu(
            title: "",
            children: [createdAtAction, updatedAtAction, selectAction, emptyTrashAction]
        )
        navigationItem.rightBarButtonItems?.first?.menu = menu
    }

    private func setupNavigation() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.gray50
        appearance.shadowColor = .clear

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        let leftItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = leftItem

        backButton.addAction(
            UIAction { [weak self] _ in
                self?.vm.didTapBack()
            }, for: .touchUpInside
        )
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: nil),
            UIBarButtonItem(image: UIImage(systemName: "magnifyingglass"), menu: nil)
        ]
        updateRightBarButtonMenu()
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

            cell.accessories = vm.isSelectionMode ? [.multiselect(displayed: .always)] : []

            switch itemIdentifier {
            case .folder(let folder):
                cell.contentConfiguration = UIHostingConfiguration {
                    FolderCardView(name: folder.name, totalCount: folder.content.count)
                }
            case .voiceNote(let voiceNote):
                cell.contentConfiguration = UIHostingConfiguration {
                    VoiceNoteCardView(
                        voiceNote: voiceNote
                    )
                }
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

    private func updateDataSource(reconfigure: Bool = false) {
        var snapshot = SnapShot()
        snapshot.appendSections([.main])
        snapshot.appendItems(vm.items)
        if reconfigure {
            snapshot.reconfigureItems(vm.items)
        }
        dataSource?.apply(snapshot, animatingDifferences: true)
    }

    private func setupAlertView() {
        alert.isHidden = !vm.showAlert
        view.addSubview(alert)
        NSLayoutConstraint.activate([
            alert.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            alert.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

// MARK: - Delegate

public extension TrashViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard vm.isSelectionMode, let item = dataSource?.itemIdentifier(for: indexPath) else { return }

        let wasteBasketItem: WasteBasketItem = switch item {
        case .folder(let folder):
            .folder(obj: folder)
        case .voiceNote(let voiceNote):
            .voiceNote(obj: voiceNote)
        }
        vm.selectItem(wasteBasketItem)
    }

    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard vm.isSelectionMode, let item = dataSource?.itemIdentifier(for: indexPath) else { return }

        let wasteBasketItem: WasteBasketItem = switch item {
        case .folder(let folder):
            .folder(obj: folder)
        case .voiceNote(let voiceNote):
            .voiceNote(obj: voiceNote)
        }
        vm.deselectItem(wasteBasketItem)
    }
}

//
// #Preview {
//    UINavigationController(rootViewController: TrashViewController(vm: TrashViewModel()))
// }
