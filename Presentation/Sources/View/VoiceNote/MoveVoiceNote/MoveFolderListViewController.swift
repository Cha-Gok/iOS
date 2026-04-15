import Domain
import UIKit

public final class MoveFolderListViewController: UIViewController {
    private let viewModel: MoveFolderListViewModel

    public init(viewModel: MoveFolderListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private typealias Item = Folder
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    private enum Section { case main }

    private lazy var dataSource = makeDataSource()

    private lazy var leftTitleLable: UILabel = {
        let label = UILabel()
        label.setTypography(text: viewModel.state.leftTitle, style: .title3)
        label.textColor = .gray950

        return label
    }()

    private lazy var addFolderButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.title = viewModel.state.addFolderButtonTitle
        configuration.image = UIImage(systemName: "plus")
        configuration.baseForegroundColor = .gray800
        configuration.contentInsets = .zero

        return UIButton(configuration: configuration)
    }()

    private lazy var titleStack: UIStackView = {
        let stackView = UIStackView()
        [leftTitleLable, addFolderButton].forEach { stackView.addArrangedSubview($0) }
        stackView.distribution = .equalSpacing

        return stackView
    }()

    private lazy var folderListView: UICollectionView = {
        let layout = UICollectionViewCompositionalLayout { _, environment in
            var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
            configuration.backgroundColor = .clear
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
            section.interGroupSpacing = 8
            return section
        }
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self

        return collectionView
    }()

    private lazy var moveButton: UIButton = {
        var configuration = UIButton.Configuration.bordered()
        configuration.contentInsets.top = 16
        configuration.contentInsets.bottom = 16
        configuration.title = viewModel.state.moveButtonTitle
        configuration.baseBackgroundColor = .gray300
        configuration.baseForegroundColor = .gray600
        configuration.background.cornerRadius = 20
        let isEnabled = viewModel.state.isMoveButtonEnabled
        configuration.baseBackgroundColor = isEnabled ? .point600 : .gray300
        configuration.baseForegroundColor = isEnabled ? .gray950 : .gray600
        let button = UIButton(configuration: configuration)
        button.addAction(UIAction(handler: { [weak self] _ in
            self?.viewModel.send(.view(.moveButtonTapped))
        }), for: .touchUpInside)
        return button
    }()

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewModel.send(.view(.onAppear))
    }

    override public func updateProperties() {
        super.updateProperties()
        applySnapshot()
    }

    private func makeDataSource() -> DataSource {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Item> { cell, _, item in
            cell.contentConfiguration = FolderCellContentConfiguration(title: item.name, number: item.content.count)
        }

        return DataSource(collectionView: folderListView) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }

    private func applySnapshot() {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(viewModel.state.folders)
        dataSource.apply(snapshot)
    }

    private func setupUI() {
        view.backgroundColor = .gray100

        for view in [titleStack, folderListView, moveButton] {
            view.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(view)
        }

        NSLayoutConstraint.activate([
            titleStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 44),
            titleStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            titleStack.heightAnchor.constraint(equalToConstant: 24),

            folderListView.topAnchor.constraint(equalTo: titleStack.bottomAnchor, constant: 24),
            folderListView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            folderListView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            moveButton.topAnchor.constraint(equalTo: folderListView.bottomAnchor, constant: 53),
            moveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            moveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            moveButton.heightAnchor.constraint(equalToConstant: 54),
            moveButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -74),
        ])
    }
}

extension MoveFolderListViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let folder = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.send(.view(.folderSelected(folder)))
    }
}

// #Preview {
//    struct StubFetchFolderUseCase: FetchFolderUseCase {
//        func fetchAll() async throws(FetchFolderUseCaseError) -> [Folder] {
//            [Folder(name: "내 폴더"), Folder(name: "작업 폴더"), Folder(name: "강의 노트")]
//        }
//
//        func fetchDeletableFolders() async throws(FetchFolderUseCaseError) -> [Folder] {
//            []
//        }
//
//        func fetch(by id: UUID) async throws(FetchFolderUseCaseError) -> Folder {
//            Folder(name: "폴더")
//        }
//    }
//    struct StubUpdateVoiceNoteUseCase: UpdateVoiceNoteUseCase {
//        func execute(_ voiceNote: VoiceNote) async throws(UpdateVoiceNoteUseCaseError) -> VoiceNote {
//            voiceNote
//        }
//    }
//    let voiceNote = VoiceNote(
//        id: UUID(),
//        title: "테스트",
//        createdAt: .now,
//        updatedAt: .now,
//        folderID: UUID(),
//        voiceRecord: VoiceRecord(audioFilePath: "", duration: 0),
//        keywords: [],
//        transcript: nil,
//        summary: nil
//    )
//    let viewModel = MoveFolderListViewModel(
//        voiceNote: voiceNote,
//        fetchFolderUseCase: StubFetchFolderUseCase(),
//        updateVoiceNoteUseCase: StubUpdateVoiceNoteUseCase()
//    )
//    MoveFolderListViewController(viewModel: viewModel)
// }
