import Observation
import UIKit

final class VoiceNoteSummaryViewController: UIViewController {
    private let viewModel: VoiceNoteViewModel

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.keyboardDismissMode = .interactive
        return cv
    }()

    private lazy var dataSource = makeDataSource()

    init(viewModel: VoiceNoteViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupLayout()
        applySnapshot()
        observeAnalysisState()
        observeSearchQuery()
        observeCurrentMatch()
    }

    /// 지정한 매치 위치로 컬렉션을 스크롤합니다.
    func scrollToMatch(_ match: VoiceNoteSearchMatch) {
        let indexPath: IndexPath
        switch match.location {
        case .keyPoint(let index):
            indexPath = IndexPath(item: index, section: Section.keyPoints.rawValue)
        case .keyword:
            indexPath = IndexPath(item: 0, section: Section.keywords.rawValue)
        case .script:
            return
        }
        guard dataSource.itemIdentifier(for: indexPath) != nil else { return }
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
    }

    private func setupLayout() {
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - Layout

private extension VoiceNoteSummaryViewController {
    func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { sectionIndex, environment in
            let sectionType = Section(rawValue: sectionIndex)

            var config = UICollectionLayoutListConfiguration(appearance: .plain)
            config.backgroundColor = .clear
            config.showsSeparators = false
            config.headerMode = sectionType == .metadata ? .none : .supplementary

            let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)

            let headerTop: CGFloat = switch sectionType {
            case .keyPoints: 26
            case .keywords: 32
            default: 0
            }
            for item in section.boundarySupplementaryItems {
                item.pinToVisibleBounds = false
                item.edgeSpacing = NSCollectionLayoutEdgeSpacing(
                    leading: nil, top: .fixed(headerTop),
                    trailing: nil, bottom: nil
                )
            }

            let cellTop: CGFloat = switch sectionType {
            case .metadata: 24
            case .keyPoints: 16
            case .keywords: 12
            default: 0
            }
            section.contentInsets = NSDirectionalEdgeInsets(top: cellTop, leading: 0, bottom: 0, trailing: 0)

            section.interGroupSpacing = switch sectionType {
            case .keyPoints: 6
            default: 0
            }

            return section
        }
    }
}

// MARK: - DataSource

private extension VoiceNoteSummaryViewController {
    func makeDataSource() -> UICollectionViewDiffableDataSource<Section, Item> {
        let metadataCellReg = UICollectionView.CellRegistration<UICollectionViewCell, Item> { [weak self] cell, _, _ in
            cell.contentConfiguration = MetadataContentConfiguration(
                folderName: self?.viewModel.folderName ?? "",
                date: self?.viewModel.metadataText1 ?? "",
                duration: self?.viewModel.metadataText2 ?? ""
            )
        }

        let keyPointCellReg = UICollectionView
            .CellRegistration<UICollectionViewCell, Item> { [weak self] cell, indexPath, item in
                guard case .keyPoint(let number, let text) = item else { return }
                let focusedRange: NSRange? = {
                    guard let match = self?.viewModel.currentMatch,
                          case .keyPoint(let idx) = match.location,
                          idx == indexPath.item else { return nil }
                    return match.range
                }()
                cell.contentConfiguration = KeyPointContentConfiguration(
                    number: number,
                    text: text,
                    searchQuery: self?.viewModel.searchQuery ?? "",
                    currentMatchRange: focusedRange
                )
            }

        let keywordsCellReg = UICollectionView.CellRegistration<UICollectionViewCell, Item> { [weak self] cell, _, _ in
            let focusedKeywordIndex: Int?
            let focusedRange: NSRange?
            if let match = self?.viewModel.currentMatch, case .keyword(let idx) = match.location {
                focusedKeywordIndex = idx
                focusedRange = match.range
            } else {
                focusedKeywordIndex = nil
                focusedRange = nil
            }
            cell.contentConfiguration = KeywordsContentConfiguration(
                keywords: self?.viewModel.keywords ?? [],
                searchQuery: self?.viewModel.searchQuery ?? "",
                focusedKeywordIndex: focusedKeywordIndex,
                focusedRange: focusedRange
            )
        }

        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: collectionView
        ) { col, indexPath, item in
            switch item {
            case .metadata:
                return col.dequeueConfiguredReusableCell(using: metadataCellReg, for: indexPath, item: item)
            case .keyPoint:
                return col.dequeueConfiguredReusableCell(using: keyPointCellReg, for: indexPath, item: item)
            case .keywords:
                return col.dequeueConfiguredReusableCell(using: keywordsCellReg, for: indexPath, item: item)
            }
        }

        let headerReg = makeHeaderRegistration()
        dataSource.supplementaryViewProvider = { col, _, indexPath in
            col.dequeueConfiguredReusableSupplementary(using: headerReg, for: indexPath)
        }

        return dataSource
    }

    func makeHeaderRegistration() -> UICollectionView.SupplementaryRegistration<VoiceNoteSectionHeaderView> {
        UICollectionView.SupplementaryRegistration<VoiceNoteSectionHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] header, _, indexPath in
            guard let self, let section = Section(rawValue: indexPath.section),
                  let title = section.headerTitle else { return }

            if section == .keyPoints, let state = regenerationChipState {
                let chip = RegenerationChip(state: state)
                let onTap: (() -> Void)? = state == .loading ? nil : { [weak self] in
                    self?.viewModel.regenerateSummary()
                }
                header.configure(title: title, trailingView: chip, onTrailingTap: onTap)
            } else {
                header.configure(title: title)
            }
        }
    }

    var regenerationChipState: RegenerationChip.State? {
        switch viewModel.voiceNote.analysisState {
        // 첫 분석 중에는 요약 섹션이 비어 있어 칩을 숨긴다.
        case .pending, .transcribing, .transcriptionFailed, .transcribed, .summarizing: return nil
        case .regenerating: return .loading
        case .completed: return viewModel.isSummaryOutdated ? .outdated : .idle
        case .summarizationFailed: return .idle
        }
    }

    func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)

        let metadataItems: [Item] = [.metadata]
        let keyPointItems = viewModel.keyPoints.map { Item.keyPoint(number: $0.number, text: $0.text) }
        let keywordItems: [Item] = [.keywords]

        snapshot.appendItems(metadataItems, toSection: .metadata)
        snapshot.appendItems(keyPointItems, toSection: .keyPoints)
        snapshot.appendItems(keywordItems, toSection: .keywords)

        snapshot.reconfigureItems(metadataItems + keywordItems)
        snapshot.reloadSections([.keyPoints])
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - Observations

private extension VoiceNoteSummaryViewController {
    func observeAnalysisState() {
        withObservationTracking {
            _ = viewModel.voiceNote.analysisState
        } onChange: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                switch self.viewModel.voiceNote.analysisState {
                case .transcribing, .summarizing, .regenerating:
                    var snapshot = self.dataSource.snapshot()
                    snapshot.reconfigureItems([.metadata])
                    snapshot.reloadSections([.keyPoints])
                    self.dataSource.apply(snapshot, animatingDifferences: false)
                case .completed, .transcribed:
                    self.applySnapshot()
                case .pending, .transcriptionFailed, .summarizationFailed:
                    break
                }
                self.observeAnalysisState()
            }
        }
    }

    func observeSearchQuery() {
        withObservationTracking {
            _ = viewModel.searchQuery
        } onChange: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.reconfigureForSearch()
                self.observeSearchQuery()
            }
        }
    }

    func observeCurrentMatch() {
        withObservationTracking {
            _ = viewModel.currentMatchIndex
            _ = viewModel.currentPage
        } onChange: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.reconfigureForSearch()
                self.observeCurrentMatch()
            }
        }
    }

    func reconfigureForSearch() {
        var snapshot = dataSource.snapshot()
        let items = snapshot.itemIdentifiers
        guard !items.isEmpty else { return }
        snapshot.reconfigureItems(items.filter {
            if case .metadata = $0 { return false }
            return true
        })
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Section / Item

extension VoiceNoteSummaryViewController {
    enum Section: Int, CaseIterable {
        case metadata
        case keyPoints
        case keywords

        var headerTitle: String? {
            switch self {
            case .metadata: return nil
            case .keyPoints: return "핵심 포인트"
            case .keywords: return "키워드"
            }
        }
    }

    enum Item: Hashable {
        case metadata
        case keyPoint(number: Int, text: String)
        case keywords
    }
}
