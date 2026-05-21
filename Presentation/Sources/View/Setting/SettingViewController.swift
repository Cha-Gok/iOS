import UIKit
import Domain

@MainActor
public final class SettingViewController: CollectionViewController {
    
    // MARK: - Type
    typealias Section = SettingViewModel.Section
    typealias Item = SettingViewModel.Item
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias SnapShot = NSDiffableDataSourceSnapshot<Section, Item>
    
    // MARK: - Component
    
    let backItem: NavigationItemButton = .init(
        normalItem: .init(title: "설정", imageName: "chevron.left"),
        selectedItem: .init(title: "설정", imageName: "chevron.left"),
        attributedString: Typography.header2.textAttributes
    )
    
    private lazy var dataSource: DataSource = makeDataSource()
    private let vm: SettingViewModel
    
    // MARK: - Initialize
    
    init(vm: SettingViewModel) {
        var listConfiguration = UICollectionLayoutListConfiguration(appearance: .plain)
        listConfiguration.backgroundColor = .clear
        listConfiguration.showsSeparators = false
        
        let layout = UICollectionViewCompositionalLayout.list(using: listConfiguration)
        self.vm = vm
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    // MARK: - LifeCycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        applySnapShot(animate: false)
    }
    
    public override func updateProperties() {
        super.updateProperties()
        applySnapShot(animate: true)
    }

    // MARK: - Setup
    
    private func setupNavigation() {
        updateNavigationBarAppearance(isTransparent: false)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backItem)
        navigationItem.leftBarButtonItem?.hidesSharedBackground = true
    }
    
    // MARK: - DataSource
    
    private func makeDataSource() -> DataSource {
        let langCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Item> { [weak self] cell,indexPath,itemIdentifier in
            guard case .lang(let language) = itemIdentifier.data else { return }
            cell.contentConfiguration = SettingLanguageContentConfiguration(
                title: itemIdentifier.title,
                subtitle: itemIdentifier.subTitle,
                language: language,
                action: { selectedLanguage in
                    self?.vm.setLanguage(selectedLanguage)
                }
            )
        }
        
        let modelCelllRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Item> { cell,indexPath,itemIdentifier in
            guard case .model(let chagokModel) = itemIdentifier.data else { return }
            cell.contentConfiguration = SettingModelContentConfiguration(
                title: itemIdentifier.title,
                model: chagokModel
            )
        }
        
        let defaultCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell,indexPath,itemIdentifier in
            var content = cell.defaultContentConfiguration()
            content.text = itemIdentifier.title
            content.secondaryText = itemIdentifier.subTitle
            content.textProperties.font = Typography.body1.font
            content.textProperties.color = .gray950
            cell.contentConfiguration = content
            cell.backgroundConfiguration = .clear()
        }
        
        let dataSource = DataSource(collectionView: collectionView) { col, indexPath, itemIdentifier in
            switch itemIdentifier.data {
            case .lang:
                return col.dequeueConfiguredReusableCell(using: langCellRegistration, for: indexPath, item: itemIdentifier)
            case .model:
                return col.dequeueConfiguredReusableCell(using: modelCelllRegistration, for: indexPath, item: itemIdentifier)
            case .none:
                return col.dequeueConfiguredReusableCell(using: defaultCellRegistration, for: indexPath, item: itemIdentifier)
            }
        }
        
        return dataSource
    }
    
    private func applySnapShot(animate: Bool) {
        var snapshot = SnapShot()
        snapshot.appendSections([.lang, .model, .label])
        let langData: [Item] = [
            Item(title: "언어 선택", subTitle: "녹음 기록 언어를 바꿉니다", data: .lang(vm.language))
        ]
        snapshot.appendItems(langData, toSection: .lang)
        
        let modelItems = [
            Item(title: "음성 인식 모델 설정", subTitle: "기본 모델", data: .model(.current))
        ]
        snapshot.appendItems(modelItems, toSection: .model)
        
        let labelItems = [
            Item(title: "앱 버전 정보", subTitle: nil, data: .none),
            Item(title: "오픈소스 라이선스", subTitle: nil, data: .none)
        ]
        snapshot.appendItems(labelItems, toSection: .label)
        
        dataSource.apply(snapshot, animatingDifferences: animate)
    }
}

#Preview {
    UINavigationController(
        rootViewController: SettingViewController(
            vm: .preview
        )
    )
}
