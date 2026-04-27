import Domain
import SwiftUI
import UIKit

public final class FolderDetailViewController: CollectionViewController {
    enum Section {
        case main
    }

    typealias DataSource = UICollectionViewDiffableDataSource<Section, ContentItem>
    typealias SnapShot = NSDiffableDataSourceSnapshot<Section, ContentItem>
    private var listConfiguration: UICollectionLayoutListConfiguration = .init(appearance: .plain)
    private var dataSource: DataSource!

    // MARK: - Component

    private lazy var backButton: NavigationItemButton = .init(
        normalItem: .init(title: vm.title, imageName: "chevron.left"),
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
        selectedItem: .init(title: "이동"),
        attributedString: Typography.title1.textAttributes
    )

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
        self?.vm.setSelectionMode(.multiple)
    }

    private lazy var selectAllAction = UIAction(
        title: "전체 선택하기",
        image: nil
    ) { [weak self] _ in
        self?.vm.setSelectionMode(.all)
    }

    private let cancelAlertButton: GlassButton = .close("취소")
    private let primaryAlertButton: GlassButton = .danger("삭제")
    private let removeAlertOverlayView: UIView = {
        let overlay = UIView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        overlay.isHidden = true
        return overlay
    }()

    private lazy var removeAlertView: AlertView = .init(
        title: "기록을 삭제할까요?",
        subTitle: "휴지통으로 이동되며,\n직접 비우기 전까지 보관돼요.",
        closeButton: cancelAlertButton,
        primaryButton: primaryAlertButton,
        tintColor: .gray200.withAlphaComponent(0.2)
    )

    private let vm: FolderDetailViewModel

    public init(vm: FolderDetailViewModel) {
        self.vm = vm
        listConfiguration.backgroundColor = .clear
        listConfiguration.showsSeparators = false
        let layout = UICollectionViewCompositionalLayout.list(using: listConfiguration)
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
        setupSwipeAction()
        setupRemoveAlert()
        setupDataSource()
        updateDataSource()
        updateNavigationBarAppearance(isTransparent: vm.showAlert)
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
        // menu
        updateOrder(vm.order)
        updateRightBarButtonMenu(vm.select)
        // navigation Item
        updateNavigationItems(vm.select)
        // dataSource
        updateDataSource(reconfigure: true)
        // Remove Alert
        updateRemoveAlert()
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

        setupRightBarButtonMenu()
        navigationItem.leftBarButtonItem?.hidesSharedBackground = true
        navigationItem.rightBarButtonItems?.forEach {
            $0.hidesSharedBackground = true
        }
    }
    
    private func setupSwipeAction() {
        
        listConfiguration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            self?.trailingAction(indexPath: indexPath)
        }

        // List 레이아웃을 사용하되, 섹션 설정을 통해 간격을 조정합니다.
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
            guard let self else { return nil }
            let config = listConfiguration
            // 개별 셀의 높이가 카드에 딱 맞게 설정되도록 여백 제거
            let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
            section.interGroupSpacing = 8
            section.contentInsets = .init(top: 12, leading: 20, bottom: 20, trailing: 20)
            return section
        }
        collectionView.setCollectionViewLayout(layout, animated: false)
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

    private func setupRemoveAlert() {
        cancelAlertButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            vm.closeAlertView()
        }, for: .touchUpInside)

        primaryAlertButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let restoreItems: [VoiceNote] = vm.selectedItems
            vm.move()
            vm.closeAlertView()
            chagokBackgroundView.makeToast("휴지통으로 이동되었어요.") { [weak self] in
                self?.vm.restore(items: restoreItems)
            }
        }, for: .touchUpInside)

        view.addSubview(removeAlertOverlayView)
        removeAlertOverlayView.addSubview(removeAlertView)
        NSLayoutConstraint.activate([
            removeAlertOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            removeAlertOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            removeAlertOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            removeAlertOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            removeAlertView.centerXAnchor.constraint(equalTo: removeAlertOverlayView.centerXAnchor),
            removeAlertView.centerYAnchor.constraint(equalTo: removeAlertOverlayView.centerYAnchor)
        ])
    }

    private func setupDataSource() {
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
                    FolderCardView(folder: folder)
                }
                .margins(.all, 0)
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
                    } completeAction: { [weak self] in
                        self?.vm.pushVoiceNote(voiceNote: voiceNote)
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

    private func updateRightBarButtonMenu(_ select: SelectionMode) {
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

    private var updateDateSectionChildren: [UIMenuElement] {
        switch vm.select {
        case .none:
            [createdAtAction, updatedAtAction]
        case .all, .multiple:
            []
        }
    }

    private var updateSelectSectionChildren: [UIMenuElement] {
        switch vm.select {
        case .none:
            [selectAction, selectAllAction]
        case .all, .multiple:
            []
        }
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

    private func updateRemoveAlert() {
        let shouldShowAlert = vm.showAlert
        removeAlertOverlayView.isHidden = !shouldShowAlert
        updateInteractionForAlert(isPresented: shouldShowAlert)
        if shouldShowAlert {
            view.bringSubviewToFront(removeAlertOverlayView)
        }
        updateNavigationBarAppearance(isTransparent: shouldShowAlert)
    }
}

// MARK: - Helper Method

private extension FolderDetailViewController {
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
            case .none:
                // TODO: 더 보기 로직 실행 ( 실행 X )
                break
            case .multiple, .all:
                // TODO: 삭제 로직 실행
                vm.openAlertView()
            }
        }
    }

    func searchAndMoveButtonAction() -> UIAction {
        UIAction { [weak self] _ in
            guard let self else { return }
            switch vm.select {
            case .none:
                // TODO: 검색 로직 실행
                vm.pushSearch()
            case .all, .multiple:
                // TODO: 이동 로직 실행
                vm.presentMoveFolder { [weak self] name in
                    self?.chagokBackgroundView.makeToast(
                        type: .normal,
                        "`\(name)` 폴더로 이동됐어요."
                    )
                }
                vm.setSelectionMode(.none)
            }
        }
    }

    func updateInteractionForAlert(isPresented: Bool) {
        collectionView.isUserInteractionEnabled = !isPresented
        backButton.isUserInteractionEnabled = !isPresented
        moreAndActionButton.isUserInteractionEnabled = !isPresented
        searchAndMoveButton.isUserInteractionEnabled = !isPresented
    }
}

// MARK: - Swipe Action Delegate

public extension FolderDetailViewController {
    private func trailingAction(indexPath: IndexPath) -> UISwipeActionsConfiguration {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return .init() }

        let deleteAction = UIContextualAction(style: .destructive, title: nil) {
            [weak self] _, _, completion in
            if case .voiceNote(let voiceNote) = item {
                self?.vm.move(id: voiceNote.id)
                // Swipe 종료 애니메이션과 목록 갱신 타이밍이 어긋나면 셀이 튕겨 보일 수 있어 즉시 반영합니다.
                self?.updateDataSource(reconfigure: true)
            }
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
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
