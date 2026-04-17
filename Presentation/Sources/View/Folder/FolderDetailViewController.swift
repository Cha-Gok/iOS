import Domain
import SwiftUI
import UIKit

public final class FolderDetailViewController: CollectionViewController {
    enum Section {
        case main
    }

    typealias DataSource = UICollectionViewDiffableDataSource<Section, LibraryItem>
    typealias SnapShot = NSDiffableDataSourceSnapshot<Section, LibraryItem>

    private var dataSource: DataSource?

    private lazy var backButton: UIButton = {
        let btn = UIButton(type: .custom) // .system 대신 .custom을 사용하여 기본 배경 효과 제거
        let symbolConfig = UIImage.SymbolConfiguration(weight: .bold)
        let backImage = UIImage(systemName: "chevron.left")?
            .withConfiguration(symbolConfig)
        btn.setImage(backImage, for: .normal)
        btn.setImage(
            UIImage(systemName: "xmark")?.withConfiguration(symbolConfig),
            for: .selected
        )
        btn.setTitle(vm.title, for: .normal)
        btn.setTitle("", for: .selected) // nil 대신 ""을 사용하여 .normal 타이틀이 나오는 것을 방지
        btn.titleLabel?.setTypography(style: .title1)
        btn.tintColor = UIColor.gray950
        return btn
    }()

    private lazy var moreAndActionButton: UIButton = {
        let btn = UIButton(type: .custom)
        let symbolConfig = UIImage.SymbolConfiguration(weight: .bold)
        btn.setImage(UIImage(systemName: "ellipsis")?.withConfiguration(symbolConfig), for: .normal)
        btn.setImage(UIImage(), for: .selected)
        btn.setTitle(nil, for: .normal)
        btn.setTitle("삭제", for: .selected)
        btn.setTitleColor(UIColor.gray950, for: .normal)
        btn.setTitleColor(UIColor.danger, for: .selected)
        btn.titleLabel?.setTypography(style: .title1)
        btn.tintColor = UIColor.gray950
        return btn
    }()

    private lazy var searchAndMoveButton: UIButton = {
        let btn = UIButton(type: .custom)
        let symbolConfig = UIImage.SymbolConfiguration(weight: .bold)
        btn.setImage(UIImage(systemName: "magnifyingglass")?.withConfiguration(symbolConfig), for: .normal)
        btn.setImage(UIImage(), for: .selected)
        btn.setTitle(nil, for: .normal)
        btn.setTitle("이동", for: .selected)
        btn.setTitleColor(UIColor.gray950, for: .normal)
        btn.setTitleColor(UIColor.gray950, for: .selected)
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
            listConfiguration.backgroundColor = .clear

            return NSCollectionLayoutSection.list(
                using: listConfiguration,
                layoutEnvironment: layoutEnvironment
            )
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
        updateRightBarButtonMenu(vm.select)
        // navigation Item
        updateNavigationItems(vm.select)
        // dataSource
        updateDataSource(reconfigure: true)
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

        backButton.addAction(backButtonAction(), for: .touchUpInside)
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(customView: moreAndActionButton),
            UIBarButtonItem(customView: searchAndMoveButton)
        ]
        moreAndActionButton.addAction(moreAndActionButtonAction(), for: .touchUpInside)
        searchAndMoveButton.addAction(searchAndMoveButtonAction(), for: .touchUpInside)

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
        moreAndActionButton.menu = menu
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
        moreAndActionButton.menu = menu
    }
    
    private func setupDataSource() {
        let cellRegistration = UICollectionView.CellRegistration {[weak self](
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
                        name: folder.name,
                        totalCount: folder.content.count
                    )
                }
            case .voiceNote(let voiceNote):
                cell.contentConfiguration = UIHostingConfiguration {
                    VoiceNoteCardView(
                        select: vm.select,
                        isSelected: vm.selectedItems.contains(voiceNote),
                        voiceNote: voiceNote
                    ) { [weak self] data, state in
                        if state {
                            self?.vm.selectItem(data)
                        } else {
                            self?.vm.deselectItem(data)
                        }
                    }
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
    
    private func updateNavigationItems(_ select: FolderDetailViewModel.Select) {
        let isEditMode = (select != .none)
        [backButton, moreAndActionButton, searchAndMoveButton].forEach {
            $0.isSelected = isEditMode
            $0.invalidateIntrinsicContentSize()
            $0.sizeToFit()
        }
        moreAndActionButton.showsMenuAsPrimaryAction = !isEditMode
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

// MARK: - Helper Method

extension FolderDetailViewController {
    func backButtonAction() -> UIAction {
        UIAction { [weak self] _ in
            guard let self else { return }
            switch vm.select {
            case .none:
                vm.didTapBack()
            case .all, .single:
                vm.setSelectionMode(.none)
            }
        }
    }

    func moreAndActionButtonAction() -> UIAction {
        UIAction { [weak self] _ in
            guard let self else { return }
            switch vm.select {
            case .none:
                // TODO: 더 보기 로직 실행
                print("더 보기 버튼 탭됨")
            case .all, .single:
                // TODO: 삭제 로직 실행
                print("삭제 버튼 탭됨")
            }
        }
    }

    func searchAndMoveButtonAction() -> UIAction {
        UIAction { [weak self] _ in
            guard let self else { return }
            switch vm.select {
            case .none:
                // TODO: 검색 로직 실행
                print("검색 버튼 탭됨")
            case .all, .single:
                // TODO: 이동 로직 실행
                print("이동 버튼 탭됨")
            }
        }
    }
}

#if DEBUG
    #Preview("폴더 상세") {
        UINavigationController(
            rootViewController: FolderDetailViewController(
                vm: .preview()
            )
        )
    }
#endif
