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

    private var cancelButton: GlassButton = .close("취소")
    private var primaryButton: GlassButton = .primary("만들기")

    private let textFieldAlertOverlayView: UIView = {
        let overlay = UIView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        overlay.isHidden = true
        return overlay
    }()

    private lazy var textField = TextFieldView(
        field: .init(
            mode: .create,
            title: "새 폴더",
            subTitle: "새로 만들 폴더의 이름을\n입력해주세요.",
            placeHolder: "폴더 이름을 적어주세요",
            errorMessage: vm.errorMessage
        ),
        cancelButton: cancelButton,
        primaryButton: primaryButton
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
        setupButtons()
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
        // textField
        updateTextFieldAlert()
        syncTextFieldField()
        // error Message
        updateErrorMessage()
        // DataSource
        updateDataSource()
    }

    // MARK: - Setup

    private func setup() {
        collectionView.showsVerticalScrollIndicator = false

        // 1. overlay — 화면 전체를 덮는 반투명 배경
        view.addSubview(textFieldAlertOverlayView)

        // 2. layoutGuide — 키보드 위 영역을 잡는 가이드 (overlay 위)
        let containerGuide = UILayoutGuide()
        textFieldAlertOverlayView.addLayoutGuide(containerGuide)

        // 3. textField — containerGuide 중앙에 배치 (overlay 위)
        textFieldAlertOverlayView.addSubview(textField)

        NSLayoutConstraint.activate([
            // overlay: 화면 전체
            textFieldAlertOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            textFieldAlertOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textFieldAlertOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textFieldAlertOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // containerGuide: safeArea top ~ 키보드 top
            containerGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerGuide.leadingAnchor.constraint(equalTo: textFieldAlertOverlayView.leadingAnchor),
            containerGuide.trailingAnchor.constraint(equalTo: textFieldAlertOverlayView.trailingAnchor),
            containerGuide.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            // textField: containerGuide 중앙
            textField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            textField.centerYAnchor.constraint(equalTo: containerGuide.centerYAnchor),
            textField.centerXAnchor.constraint(equalTo: containerGuide.centerXAnchor),
            textField.topAnchor.constraint(greaterThanOrEqualTo: containerGuide.topAnchor, constant: 20),
            textField.bottomAnchor.constraint(lessThanOrEqualTo: containerGuide.bottomAnchor, constant: -20)
        ])
    }

    private func setupNavigationBar() {
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

    private func setupButtons() {
        cancelButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                textField.endEditing(true)
                textField.field.text = ""
                vm.closeTextField()
            },
            for: .touchUpInside
        )

        primaryButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                let name = textField.field.text

                switch vm.mode {
                case .create:
                    vm.create(name: name)
                case .edit:
                    vm.update(name: name)
                }
                textField.endEditing(true)
                textField.field.text = ""
            },
            for: .touchUpInside
        )
    }
}

// MARK: - Update Method

extension FolderViewController {
    private func updateErrorMessage() {
        textField.field.errorMessage = vm.errorMessage
    }

    private func syncTextFieldField() {
        textField.field.mode = vm.mode

        switch vm.mode {
        case .create:
            textField.field.title = "새 폴더"
            textField.field.subTitle = "새로 만들 폴더의 이름을\n입력해주세요."
            textField.field.placeHolder = "폴더 이름을 적어주세요"
            textField.field.errorMessage = vm.errorMessage
            if !vm.showTextField {
                textField.field.text = ""
            }
        case .edit:
            textField.field.title = "폴더 이름 수정"
            textField.field.subTitle = "수정할 폴더의 이름을\n입력해주세요."
            textField.field.placeHolder = "폴더 이름을 적어주세요"
            textField.field.errorMessage = vm.errorMessage
            textField.field.text = vm.editFolder?.name ?? ""
        }
    }

    private func updateTextFieldAlert() {
        let shouldShowAlert = vm.showTextField
        textFieldAlertOverlayView.isHidden = !shouldShowAlert
        updateInteractionForAlert(isPresented: shouldShowAlert)
        if shouldShowAlert {
            view.bringSubviewToFront(textFieldAlertOverlayView)
        }
        updateNavigationBarAppearance(isTransparent: shouldShowAlert)
    }

    func updateInteractionForAlert(isPresented: Bool) {
        collectionView.isUserInteractionEnabled = !isPresented
        backButton.isUserInteractionEnabled = !isPresented
        addButton.isUserInteractionEnabled = !isPresented
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
                self?.updateDataSource(animated: false)
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

#if DEBUG
    #Preview("개인 폴더") {
        UINavigationController(
            rootViewController: FolderViewController(
                vm: .preview()
            )
        )
    }
#endif
