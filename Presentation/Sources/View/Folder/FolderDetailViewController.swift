import Domain
import SwiftUI
import UIKit

public final class FolderDetailViewController: UICollectionViewController {
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
        btn.setTitle(vm.title, for: .normal)
        btn.titleLabel?.setTypography(style: .title1)
        btn.tintColor = UIColor.gray950
        return btn
    }()

    // MARK: - Component

    private lazy var createdAtAction = UIAction(
        title: "생성일 순"
    ) { [weak self] _ in
        self?.vm.setOrder(.createdAt)
    }

    private lazy var updatedAtAction = UIAction(
        title: "수정일 순"
    ) { [weak self] _ in
        self?.vm.setOrder(.updatedAt)
    }

    private lazy var selectAction = UIAction(
        title: "선택하기",
        image: nil
    ) { [weak self] _ in
        self?.vm.setSelectionMode(.single)
    }
    
    private lazy var selectAllAction = UIAction(
        title: "전체 선택하기",
        image: nil
    ) { [weak self] _ in
        self?.vm.setSelectionMode(.all)
    }
    
    private lazy var cancelAction = UIAction(
        title: "취소하기",
        image: nil
    ) { [weak self] _ in
        self?.vm.setSelectionMode(.none)
    }
    
    private lazy var moveAction = UIAction(
        title: "파일 이동하기",
        image: nil
    ) { [weak self] _ in
        
    }
    
    private lazy var deleteAction = UIAction(
        title: "삭제하기",
        image: nil,
        attributes: .destructive
    ) { [weak self] _ in
        
    }

    private let vm: FolderDetailViewModel

    public init(vm: FolderDetailViewModel) {
        self.vm = vm
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            var listConfiguration = UICollectionLayoutListConfiguration(appearance: .plain)
            listConfiguration.headerMode = .none
            listConfiguration.showsSeparators = false
            listConfiguration.backgroundColor = .gray50

            return NSCollectionLayoutSection.list(using: listConfiguration, layoutEnvironment: layoutEnvironment)
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
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        vm.fetchItems()
    }

    override public func updateProperties() {
        super.updateProperties()
        // menu
        updateOrder(vm.order)
        // dataSource
        updateDataSource(reconfigure: true)
        updateRightBarButtonMenu(vm.select)
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
        setupRightBarButtonMenu()
        navigationItem.leftBarButtonItem?.hidesSharedBackground = true
        navigationItem.rightBarButtonItems?.forEach {
            $0.hidesSharedBackground = true
        }
    }

    private func setupRightBarButtonMenu() {
        let dateSection: UIMenu = .init(
            title: "",
            options: .displayInline,
            children: [createdAtAction, updatedAtAction]
        )
        
        let selectSection: UIMenu = .init(
            title: "",
            options: .displayInline,
            children: [selectAction, selectAllAction]
        )
        let menu: UIMenu = .init(
            title: "",
            children: [dateSection, selectSection]
        )
        navigationItem.rightBarButtonItems?.first?.menu = menu
    }
    
    private func setupDataSource() {
        let cellRegistration = UICollectionView.CellRegistration {(
            cell: UICollectionViewListCell,
            indexPath: IndexPath,
            itemIdentifier: LibraryItem
        ) in
            var backgroundConfig = UIBackgroundConfiguration.listCell()
            backgroundConfig.backgroundColor = .clear
            cell.backgroundConfiguration = backgroundConfig

            switch itemIdentifier {
            case .folder(let folder):
                cell.contentConfiguration = UIHostingConfiguration {
                    VoiceNoteCardView(
                        title: folder.name,
                        subTitle: folder.createdAt.description
                    )
                }
            case .voiceNote(let voiceNote):
                cell.contentConfiguration = UIHostingConfiguration {
                    VoiceNoteCardView(
                        title: voiceNote.title,
                        subTitle: voiceNote.createdAt.description
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
    }
}

// MARK: - Update Method

extension FolderDetailViewController {
    private func updateOrder(_ order: FolderDetailViewModel.Order) {
        switch order {
        case .createdAt:
            createdAtAction.image = UIImage(systemName: "checkmark")
            updatedAtAction.image = nil
        case .updatedAt:
            createdAtAction.image = nil
            updatedAtAction.image = UIImage(systemName: "checkmark")
        }
    }
    
    private func updateRightBarButtonMenu(_ select: FolderDetailViewModel.Select) {
        let dateSection: UIMenu = .init(
            title: "",
            options: .displayInline,
            children: updateDateSectionChildren
        )

        let selectSection: UIMenu = .init(
            title: "",
            options: .displayInline,
            children: updateSelectSectionChildren
        )
        let menu: UIMenu = .init(
            title: "",
            children: [dateSection, selectSection]
        )
        navigationItem.rightBarButtonItems?.first?.menu = menu
    }
    
    private var updateDateSectionChildren: [UIMenuElement] {
        switch vm.select {
        case .none:
            [createdAtAction, updatedAtAction]
        case .all, .single:
            []
        }
    }
    
    private var updateSelectSectionChildren: [UIMenuElement] {
        switch vm.select {
        case .none:
            [selectAction, selectAllAction]
        case .all, .single:
            [cancelAction, moveAction, deleteAction]
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
}

// MARK: - Delegate

public extension FolderDetailViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }

    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
    }
}

#if DEBUG
    #Preview("개인 폴더 상세") {
        UINavigationController(
            rootViewController: FolderDetailViewController(
                vm: .preview()
            )
        )
    }
#endif
