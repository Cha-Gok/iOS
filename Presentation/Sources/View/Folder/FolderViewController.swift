import Domain
import Observation
import SwiftUI
import UIKit

public final class FolderViewController: CollectionViewController {
    enum Section {
        case main
    }

    typealias DataSource = UICollectionViewDiffableDataSource<Section, ContentItem>
    typealias SnapShot = NSDiffableDataSourceSnapshot<Section, ContentItem>
    private let vm: FolderViewModel
    private var dataSource: DataSource!
    private var listConfiguration: UICollectionLayoutListConfiguration = .init(appearance: .plain)

    // MARK: - Component

    private lazy var backButton: NavigationItemButton = .init(
        normalItem: .init(title: " \(vm.category.title)", imageName: "chevron.left"),
        selectedItem: .init(title: " \(vm.category.title)", imageName: "chevron.left"),
        attributedString: Typography.title1.textAttributes
    )

    private lazy var searchButton: NavigationItemButton = .init(
        normalItem: .init(imageName: "magnifyingglass"),
        selectedItem: .init(imageName: "magnifyingglass"),
        attributedString: Typography.title1.textAttributes
    )

    private lazy var addButton: NavigationItemButton = .init(
        normalItem: .init(imageName: "folder.badge.plus"),
        selectedItem: .init(imageName: "folder.badge.plus"),
        attributedString: Typography.title1.textAttributes
    )

    // MARK: - Initialize

    public init(vm: FolderViewModel) {
        self.vm = vm
        listConfiguration.backgroundColor = .clear
        listConfiguration.showsSeparators = false
        let layout = UICollectionViewCompositionalLayout.list(using: listConfiguration)
        super.init(collectionViewLayout: layout)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - LifeCycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupNavigationBar()
        setupSwipeAction()
        setupDataSource()
        updateDataSource(animated: false)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        vm.fetchAll()
    }

    override public func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }

    override public func updateProperties() {
        super.updateProperties()
        // Naviagation
        updateNavigationBarAppearance(isTransparent: false)
        // DataSource
        updateDataSource()
    }

    // MARK: - Setup

    private func setup() {
        collectionView.showsVerticalScrollIndicator = false
    }

    private func setupNavigationBar() {
        vm.showFolderAlert = { [weak self] field in
            guard let self else { return }
            if field.mode == .create {
                vm.alertCoordinator?.presentAlert(environment: .createFolder(field), delegate: self)
            } else {
                vm.alertCoordinator?.presentAlert(environment: .updateFolder(field), delegate: self)
            }
        }

        backButton.addAction(
            UIAction { [weak self] _ in
                self?.vm.didTapBack()
            }, for: .touchUpInside
        )
        let leftItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = leftItem

        searchButton.addAction(
            UIAction { [weak self] _ in
                self?.vm.pushSearch()
            }, for: .touchUpInside
        )

        addButton.addAction(
            UIAction { [weak self] _ in
                self?.vm.openTextField()
            }, for: .touchUpInside
        )
        let rightSearchItem = UIBarButtonItem(customView: searchButton)
        let rightAddItem = UIBarButtonItem(customView: addButton)
        navigationItem.rightBarButtonItems = [rightAddItem, rightSearchItem]
        navigationItem.leftBarButtonItem?.hidesSharedBackground = true
        navigationItem.rightBarButtonItems?.forEach { $0.hidesSharedBackground = true }
    }

    /// 오른쪽 Swipe 액션을 제어하는 함수
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
            section.contentInsets = .init(top: 14, leading: 20, bottom: 14, trailing: 20)
            return section
        }
        collectionView.setCollectionViewLayout(layout, animated: false)
    }
}

// MARK: - Diffable DataSource

extension FolderViewController {
    private func setupDataSource() {
        let cellRegistraint = UICollectionView
            .CellRegistration<UICollectionViewCell, ContentItem> { cell, indexPath, item in
                cell.backgroundConfiguration = .clear()
                cell.contentConfiguration = UIHostingConfiguration {
                    switch item {
                    case .folder(let data):
                        FolderCardView(
                            folder: data,
                            completeAction: { [weak self] in
                                self?.vm.pushDetail(data)
                            }
                        )
                    case .voiceNote(let data):
                        VoiceNoteCardView(
                            voiceNote: data
                        )
                    }
                }
                .margins(.all, 0)
            }

        dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: { col, indexPath, item in
                return col.dequeueConfiguredReusableCell(using: cellRegistraint, for: indexPath, item: item)
            }
        )
        updateDataSource()
    }

    private func updateDataSource(animated: Bool = true) {
        var snapshot = SnapShot()
        snapshot.appendSections([.main])
        snapshot.appendItems(vm.category.items, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

// MARK: - Swipe Action Delegate

public extension FolderViewController {
    private func trailingAction(indexPath: IndexPath) -> UISwipeActionsConfiguration {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return .init() }

        let deleteAction = UIContextualAction(style: .destructive, title: nil) {
            [weak self] _, _, completion in
            if case .folder(let folder) = item {
                self?.vm.move(folder: folder)
                // Swipe 종료 애니메이션과 목록 갱신 타이밍이 어긋나면 셀이 튕겨 보일 수 있어 즉시 반영합니다.
                self?.updateDataSource(animated: true)
            }
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")

        let editAction = UIContextualAction(style: .normal, title: nil) {
            [weak self] _, _, completion in
            if case .folder(let folder) = item {
                self?.vm.openTextField(for: folder)
            }
            completion(true)
        }
        editAction.backgroundColor = UIColor.gray500
        editAction.image = UIImage(systemName: "pencil")

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}

// MARK: - Cell Touch Delegate

public extension FolderViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 터치 시 배경색 진해진 상태를 부드럽게 원래대로 돌려줍니다.
        collectionView.deselectItem(at: indexPath, animated: true)

        // 클릭한 셀의 데이터를 가져옵니다.
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        // ContentItem이 folder 모델일 경우 상세 화면으로 이동합니다.
        if case .folder(let folder) = item {
            vm.pushDetail(folder)
        }
    }
}

// MARK: - Delegate

extension FolderViewController: ChaGokAlertButtonTappedDelegate {
    public func createFolderCloseButtonTapped(_ alertVC: ChaGokAlertViewController) {
        alertVC.dismiss(animated: true) { [weak self] in
            self?.vm.closeTextField()
        }
    }

    public func createFolderPrimaryButtonTapped(_ alertVC: ChaGokAlertViewController) {
        guard let name = alertVC.inputText, !name.isEmpty else { return }
        vm.create(name: name)

        if let errorMessage = vm.errorMessage {
            alertVC.setErrorMessage(errorMessage)
        } else {
            alertVC.dismiss(animated: true) { [weak self] in
                self?.vm.closeTextField()
            }
        }
    }

    public func updateFolderCloseButtonTapped(_ alertVC: ChaGokAlertViewController) {
        alertVC.dismiss(animated: true) { [weak self] in
            self?.vm.closeTextField()
        }
    }

    public func updateFolderPrimaryButtonTapped(_ alertVC: ChaGokAlertViewController) {
        guard let name = alertVC.inputText, !name.isEmpty else { return }
        vm.update(name: name)

        if let errorMessage = vm.errorMessage {
            alertVC.setErrorMessage(errorMessage)
        } else {
            alertVC.dismiss(animated: true) { [weak self] in
                self?.vm.closeTextField()
            }
        }
    }
}

#if DEBUG
    #Preview("개인 폴더") {
        UINavigationController(
            rootViewController: FolderViewController(
                vm: .preview()
            )
        )
    }
#endif
