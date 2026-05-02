import Observation
import UIKit

final class VoiceNoteSummaryViewController: UICollectionViewController {
    private let viewModel: VoiceNoteViewModel

    private lazy var dataSource = makeDataSource()

    init(viewModel: VoiceNoteViewModel) {
        self.viewModel = viewModel
        super.init(collectionViewLayout: Self.makeLayout())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.keyboardDismissMode = .interactive

        applySnapshot()
        observeAnalysisState()
        observeSearchQuery()
        observeCurrentMatch()
    }

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
}

// MARK: - Layout

private extension VoiceNoteSummaryViewController {
    static func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { sectionIndex, environment in
            let sectionType = Section(rawValue: sectionIndex)

            var config = UICollectionLayoutListConfiguration(appearance: .plain)
            config.backgroundColor = .clear
            config.showsSeparators = false
            config.headerMode = sectionType == .metadata ? .none : .supplementary

            let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)

            let headerTop: CGFloat = switch sectionType {
            case .keyPoints: Constant.summarySectionKeyPointsHeaderTop
            case .keywords: Constant.summarySectionKeywordsHeaderTop
            default: 0
            }
            for item in section.boundarySupplementaryItems {
                item.pinToVisibleBounds = false
                item.edgeSpacing = NSCollectionLayoutEdgeSpacing(
                    leading: nil, top: .fixed(headerTop),
                    trailing: nil, bottom: nil
                )
                item.contentInsets = NSDirectionalEdgeInsets(
                    top: 0,
                    leading: Constant.summarySectionHorizontalInset,
                    bottom: 0,
                    trailing: Constant.summarySectionHorizontalInset
                )
            }

            let cellTop: CGFloat = switch sectionType {
            case .metadata: Constant.summarySectionMetadataTopInset
            case .keyPoints: Constant.summarySectionKeyPointsTopInset
            case .keywords: Constant.summarySectionKeywordsTopInset
            default: 0
            }
            section.contentInsets = NSDirectionalEdgeInsets(
                top: cellTop,
                leading: Constant.summarySectionHorizontalInset,
                bottom: 0,
                trailing: Constant.summarySectionHorizontalInset
            )

            section.interGroupSpacing = switch sectionType {
            case .keyPoints: Constant.summarySectionKeyPointsGroupSpacing
            case .keywords: Constant.keywordChipLineSpacing
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
                cell.contentConfiguration = KeyPointContentConfiguration(
                    number: number,
                    text: text,
                    highlightRanges: self?.viewModel.highlightRanges(in: text) ?? [],
                    focusedRange: self?.viewModel.focusedKeyPointRange(at: indexPath.item)
                )
            }

        let keywordsCellReg = UICollectionView.CellRegistration<UICollectionViewCell, Item> { [weak self] cell, _, _ in
            let keywords = self?.viewModel.keywords ?? []
            let keywordMatch = self?.viewModel.focusedKeywordMatch()
            cell.contentConfiguration = KeywordsContentConfiguration(
                keywords: keywords,
                keywordHighlightRanges: keywords.map { self?.viewModel.highlightRanges(in: $0) ?? [] },
                focusedKeywordIndex: keywordMatch?.index,
                focusedRange: keywordMatch?.range
            )
        }

        let keyPointSkeletonCellReg = UICollectionView.CellRegistration<UICollectionViewCell, Item> { cell, _, item in
            guard case .keyPointSkeleton(let number, let beginOffset) = item else { return }
            cell.contentConfiguration = KeyPointSkeletonContentConfiguration(
                number: number,
                beginOffset: beginOffset
            )
        }

        let keywordsSkeletonCellReg = UICollectionView.CellRegistration<UICollectionViewCell, Item> { cell, _, item in
            guard case .keywordsSkeleton(let beginOffset) = item else { return }
            cell.contentConfiguration = KeywordsSkeletonContentConfiguration(beginOffset: beginOffset)
        }

        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            switch item {
            case .metadata:
                return collectionView.dequeueConfiguredReusableCell(using: metadataCellReg, for: indexPath, item: item)
            case .keyPoint:
                return collectionView.dequeueConfiguredReusableCell(using: keyPointCellReg, for: indexPath, item: item)
            case .keywords:
                return collectionView.dequeueConfiguredReusableCell(using: keywordsCellReg, for: indexPath, item: item)
            case .keyPointSkeleton:
                return collectionView.dequeueConfiguredReusableCell(
                    using: keyPointSkeletonCellReg, for: indexPath, item: item
                )
            case .keywordsSkeleton:
                return collectionView.dequeueConfiguredReusableCell(
                    using: keywordsSkeletonCellReg, for: indexPath, item: item
                )
            }
        }

        let headerReg = makeHeaderRegistration()
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerReg, for: indexPath)
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
        case .pending, .summarizing, .transcribed, .transcribing, .transcriptionFailed: return nil
        case .regenerating: return .loading
        case .completed: return viewModel.isSummaryOutdated ? .outdated : .idle
        case .summarizationFailed: return .idle
        }
    }

    var isShowingSkeleton: Bool {
        switch viewModel.voiceNote.analysisState {
        case .pending, .regenerating, .summarizing, .transcribed, .transcribing:
            return true
        case .completed, .summarizationFailed, .transcriptionFailed:
            return false
        }
    }

    func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)

        let metadataItems: [Item] = [.metadata]
        snapshot.appendItems(metadataItems, toSection: .metadata)

        let keyPointItems: [Item]
        let keywordItems: [Item]
        if isShowingSkeleton {
            keyPointItems = (0 ..< Constant.skeletonKeyPointCount).map {
                .keyPointSkeleton(number: $0 + 1, beginOffset: Double($0) * Constant.skeletonStaggerOffset)
            }
            keywordItems = (0 ..< Constant.skeletonKeywordCount).map {
                .keywordsSkeleton(beginOffset: Double($0) * Constant.skeletonStaggerOffset)
            }
        } else {
            keyPointItems = viewModel.keyPoints.map { Item.keyPoint(number: $0.number, text: $0.text) }
            keywordItems = [.keywords]
        }

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
                self.applySnapshot()
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
        case keyPointSkeleton(number: Int, beginOffset: CFTimeInterval)
        case keywordsSkeleton(beginOffset: CFTimeInterval)
    }
}
