import Domain
import Observation
import SwiftUI
import UIKit

public final class FolderViewController: CollectionViewController {
    enum Section {
        case main
    }

    typealias DataSource = UICollectionViewDiffableDataSource<Section, LibraryItem>
    typealias SnapShot = NSDiffableDataSourceSnapshot<Section, LibraryItem>
    private let vm: FolderViewModel
    private var dataSource: DataSource!
    private var listConfiguration: UICollectionLayoutListConfiguration = .init(appearance: .plain)

    // MARK: - Component

    private lazy var backButton: UIButton = {
        let btn = UIButton(type: .system)
        let backImage = UIImage(systemName: "chevron.left")?
            .withConfiguration(UIImage.SymbolConfiguration(weight: .bold))
        btn.setImage(backImage, for: .normal)
        btn.setTitle(" \(vm.category.title)", for: .normal)
        btn.titleLabel?.setTypography(style: .title1)
        btn.tintColor = UIColor.gray950
        return btn
    }()

    private lazy var addButton: UIButton = {
        let btn = UIButton(type: .system)
        let addImage = UIImage(systemName: "folder.badge.plus")?
            .withConfiguration(UIImage.SymbolConfiguration(weight: .bold))
        btn.setImage(addImage, for: .normal)
        btn.tintColor = UIColor.gray950
        return btn
    }()

    private var cancelButton: GlassButton = .close("취소")
    private var primaryButton: GlassButton = .primary("만들기")

    private lazy var textField = TextFieldView(
        field: .init(
            mode: .create,
            title: "새 폴더",
            subTitle: "새로 만들 폴더의 이름을\n입력해주세요.",
            placeHolder: "폴더 이름을 적어주세요"
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
        syncTextFieldField()
        textField.isHidden = !vm.showTextField
        updateDataSource()
    }

    // MARK: - Setup

    private func setup() {
        collectionView.showsVerticalScrollIndicator = false
        let containerGuide = UILayoutGuide()
        view.addLayoutGuide(containerGuide)
        view.addSubview(textField)

        NSLayoutConstraint.activate([
            containerGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerGuide.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            textField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            textField.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.35),
            textField.centerXAnchor.constraint(equalTo: containerGuide.centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: containerGuide.centerYAnchor)
        ])
    }

    private func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.gray50
        backButton.addAction(
            UIAction { [weak self] _ in
                self?.vm.didTapBack()
            }, for: .touchUpInside
        )
        let leftItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = leftItem

        addButton.addAction(
            UIAction { [weak self] _ in
                self?.vm.openTextField()
            }, for: .touchUpInside
        )
        let rightItem = UIBarButtonItem(customView: addButton)
        navigationItem.rightBarButtonItem = rightItem
        navigationItem.leftBarButtonItem?.hidesSharedBackground = true
        navigationItem.rightBarButtonItem?.hidesSharedBackground = true
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
                let name = textField.field.trimmedText
                guard !name.isEmpty else { return }

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

    private func syncTextFieldField() {
        textField.field.mode = vm.mode

        switch vm.mode {
        case .create:
            textField.field.title = "새 폴더"
            textField.field.subTitle = "새로 만들 폴더의 이름을\n입력해주세요."
            textField.field.placeHolder = "폴더 이름을 적어주세요"
            if !vm.showTextField {
                textField.field.text = ""
            }
        case .edit:
            textField.field.title = "폴더 이름 수정"
            textField.field.subTitle = "수정할 폴더의 이름을\n입력해주세요."
            textField.field.placeHolder = "폴더 이름을 적어주세요"
            textField.field.text = vm.editFolder?.name ?? ""
        }
    }
}

// MARK: - Diffable DataSource

extension FolderViewController {
    private func setupDataSource() {
        let cellRegistraint = UICollectionView
            .CellRegistration<UICollectionViewCell, LibraryItem> { cell, indexPath, item in
                cell.backgroundConfiguration = .clear()
                cell.contentConfiguration = UIHostingConfiguration {
                    switch item {
                    case .folder(let data):
                        FolderCardView(
                            name: data.name,
                            totalCount: data.content.count
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

        let deleteAction = UIContextualAction(style: .destructive, title: "삭제") {
            [weak self] _, _, completion in
            if case .folder(let folder) = item {
                self?.vm.move(folder: folder)
            }
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")

        let editAction = UIContextualAction(style: .normal, title: "수정") {
            [weak self] _, _, completion in
            if case .folder(let folder) = item {
                self?.vm.openTextField(for: folder)
            }
            completion(true)
        }
        editAction.backgroundColor = UIColor.gray500
        editAction.image = UIImage(systemName: "pencil")

        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
}

// MARK: - Cell Touch Delegate

public extension FolderViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 터치 시 배경색 진해진 상태를 부드럽게 원래대로 돌려줍니다.
        collectionView.deselectItem(at: indexPath, animated: true)

        // 클릭한 셀의 데이터를 가져옵니다.
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        // LibraryItem이 folder 모델일 경우 상세 화면으로 이동합니다.
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
