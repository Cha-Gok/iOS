import UIKit

public final class MainViewController: UIViewController {
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let c = UICollectionView(frame: .zero, collectionViewLayout: layout)
        c.translatesAutoresizingMaskIntoConstraints = false

        return c
    }()

    let colors: [[UIColor]] = [
        [.red, .red, .red, .red, .red],
        (0 ..< 10).map { _ in .blue }
    ]

    override public func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupCollectionView()
    }

    private func setup() {
        view.backgroundColor = .gray200
    }

    private func setupCollectionView() {
        view.addSubview(collectionView)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MainViewCell.self, forCellWithReuseIdentifier: MainViewCell.reuseIdentifier)
        collectionView.setCollectionViewLayout(
            createLayout(),
            animated: false
        )

        collectionViewConstraint()
    }

    private func collectionViewConstraint() {
        NSLayoutConstraint.activate([
            collectionView.widthAnchor.constraint(equalTo: view.widthAnchor),
            collectionView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
    }
}

// MARK: - Layout Custom

extension MainViewController {
    private func createLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            switch sectionIndex {
            case 0:
                self?.createSection(
                    itemWidth: .fractionalWidth(1.0),
                    itemHeight: .absolute(100),
                    groupWidth: .fractionalWidth(0.3),
                    groupHeight: .absolute(100),
                    interGroupSpacing: 10,
                    contentInsets: .init(top: 10, leading: 10, bottom: 10, trailing: 10),
                    scrollBehavior: .continuous
                )
            default:
                self?.createSection(
                    itemWidth: .fractionalWidth(1.0),
                    itemHeight: .absolute(100),
                    groupWidth: .fractionalWidth(1.0),
                    groupHeight: .absolute(100),
                    interGroupSpacing: 10,
                    contentInsets: .init(top: 10, leading: 10, bottom: 10, trailing: 10),
                    scrollBehavior: .none
                )
            }
        }
    }

    private func createSection(
        itemWidth: NSCollectionLayoutDimension,
        itemHeight: NSCollectionLayoutDimension,
        groupWidth: NSCollectionLayoutDimension,
        groupHeight: NSCollectionLayoutDimension,
        interItemSpacing: NSCollectionLayoutSpacing = .fixed(0),
        interGroupSpacing: CGFloat = 0.0,
        contentInsets: NSDirectionalEdgeInsets = .zero,
        headerHeight: CGFloat? = nil,
        scrollBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior = .none
    ) -> NSCollectionLayoutSection {
        let itemSize: NSCollectionLayoutSize = .init(widthDimension: itemWidth, heightDimension: itemHeight)
        let groupSize: NSCollectionLayoutSize = .init(widthDimension: groupWidth, heightDimension: groupHeight)

        let item: NSCollectionLayoutItem = .init(layoutSize: itemSize)
        let group: NSCollectionLayoutGroup = .vertical(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = interItemSpacing
        let section: NSCollectionLayoutSection = .init(group: group)
        section.interGroupSpacing = interGroupSpacing
        section.contentInsets = contentInsets
        section.orthogonalScrollingBehavior = scrollBehavior
        // Header Content 추가

        return section
    }
}

extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        colors.count
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        colors[section].count
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MainViewCell.reuseIdentifier, for: indexPath)

        cell.backgroundColor = colors[indexPath.section][indexPath.item]
        cell.layer.borderColor = UIColor.darkGray.cgColor
        cell.layer.borderWidth = 1.0
        return cell
    }
}

// #Preview {
//    MainViewController()
// }
