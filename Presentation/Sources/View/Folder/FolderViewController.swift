import Domain
import Observation
import UIKit

public final class FolderViewController: UITableViewController {
    private enum Section {
        case main
    }

    private let vm: FolderViewModel
    private var dataSource: UITableViewDiffableDataSource<Section, LibraryItem>!

    // MARK: - Component

    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.3)
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let textField: TextFieldView = {
        let tf = TextFieldView(
            isEdit: false,
            title: "새 폴더",
            subTitle: "새로 만들 폴더의 이름을 입력해주세요.",
            placeholder: "폴더 이름을 적어주세요"
        )
        tf.alpha = 0
        tf.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        return tf
    }()

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

    // MARK: - Initialize

    public init(vm: FolderViewModel) {
        self.vm = vm
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - LifeCycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupNavigationBar()
        bindTextFieldCancel()
        bindTextFieldConfirm()
        setupDataSource()
        updateDataSource(animated: false)
    }

    override public func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }

    override public func updateProperties() {
        super.updateProperties()
        if vm.showAlert {
            presentAlert()
        } else {
            dismissAlert()
        }
        // tableview 업데이트
        updateDataSource()
    }

    // MARK: - Setup

    private func setup() {
        view.backgroundColor = UIColor.gray50
        tableView.register(FolderViewCell.self, forCellReuseIdentifier: FolderViewCell.reuseIdentifier)
    }

    private func setupNavigationBar() {
        backButton.addAction(
            UIAction { [weak self] _ in
                self?.vm.didTapBack()
            }, for: .touchUpInside
        )
        let leftItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = leftItem

        addButton.addAction(
            UIAction { [weak self] _ in
                self?.textField.configure(
                    isEdit: false,
                    title: "새 폴더",
                    subTitle: "새로 만들 폴더의 이름을 입력해주세요."
                )
                self?.vm.openTextFieldView()
            }, for: .touchUpInside
        )
        let rightItem = UIBarButtonItem(customView: addButton)
        navigationItem.rightBarButtonItem = rightItem

        navigationItem.leftBarButtonItem?.hidesSharedBackground = true
        navigationItem.rightBarButtonItem?.hidesSharedBackground = true
    }
}

// MARK: - Diffable DataSource

extension FolderViewController {
    private func setupDataSource() {
        dataSource = UITableViewDiffableDataSource<
            Section,
            LibraryItem
        >(tableView: tableView) { tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: FolderViewCell.reuseIdentifier,
                for: indexPath
            ) as? FolderViewCell else {
                return UITableViewCell()
            }
            cell.configure(with: item)
            return cell
        }
    }

    private func updateDataSource(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, LibraryItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(vm.category.items, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

// MARK: - Bind TextField

extension FolderViewController {
    private func bindTextFieldCancel() {
        textField.onCancel = { [weak self] in
            self?.vm.closeTextFieldView()
        }
    }

    private func bindTextFieldConfirm() {
        textField.onConfirm = { [weak self] name in
            guard let self else { return }
            if textField.isEdit {
                vm.update(name: name)
            } else {
                vm.create(name: name)
            }
        }
    }
}

// MARK: - TextField Alert Animation

extension FolderViewController {
    private func presentAlert() {
        guard overlayView.superview == nil else { return }

        // Add to window or navigation view to avoid scrolling with table
        let parentView = navigationController?.view ?? view!
        parentView.addSubview(overlayView)
        parentView.addSubview(textField)

        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: parentView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor)
        ])

        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.overlayView.alpha = 1
            self.textField.alpha = 1
            self.textField.transform = .identity
        }
    }

    private func dismissAlert() {
        UIView.animate(withDuration: 0.2, animations: {
            self.overlayView.alpha = 0
            self.textField.alpha = 0
            self.textField.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.overlayView.removeFromSuperview()
            self.textField.removeFromSuperview()
        }
    }
}

// MARK: - Swipe Action Delegate

public extension FolderViewController {
    override func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return nil }

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
                self?.textField.configure(
                    isEdit: true,
                    name: folder.name,
                    title: "폴더 이름 수정",
                    subTitle: "수정할 폴더의 이름을 입력해주세요."
                )
                self?.vm.openTextFieldView(for: folder)
            }
            completion(true)
        }
        editAction.backgroundColor = UIColor.gray500
        editAction.image = UIImage(systemName: "pencil")

        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
}

// #Preview {
//    let dummyItems: [LibraryItem] = [
//        .folder(
//            Folder(
//                name: "개인 아카이브",
//                content: [
//                    VoiceNote(
//                        title: "백업",
//                        folderID: UUID(),
//                        voiceRecord: VoiceRecord(audioFilePath: URL(string: "file://2")!, duration: 10)
//                    )
//                ]
//            )
//        ),
//        .folder(
//            Folder(
//                name: "test 1",
//                content: [
//                    VoiceNote(
//                        title: "백업",
//                        folderID: UUID(),
//                        voiceRecord: VoiceRecord(audioFilePath: URL(string: "file://2")!, duration: 10)
//                    )
//                ]
//            )
//        )
//    ]
//
//    let testFolder = CategoryToggle(imageName: "folder", title: "개인 폴더", items: dummyItems)
//    let vm = FolderViewModel(category: testFolder)
//    let folderVC = FolderViewController(vm: vm)
//
//    return UINavigationController(rootViewController: folderVC)
// }
