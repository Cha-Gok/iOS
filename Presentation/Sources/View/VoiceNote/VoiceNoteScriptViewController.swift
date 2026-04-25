import Observation
import UIKit

final class VoiceNoteScriptViewController: UICollectionViewController {
    private let viewModel: VoiceNoteViewModel

    private lazy var dataSource = makeDataSource()

    init(viewModel: VoiceNoteViewModel) {
        self.viewModel = viewModel
        super.init(collectionViewLayout: Self.makeLayout(viewModel: viewModel))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.keyboardDismissMode = .interactive

        applySnapshot()
        observeTranscriptSections()
        observePlayingParagraph()
        observeEditingMode()
        observeSearchState()
        observeAnalysisState()
    }

    /// 지정한 매치 위치의 스크립트 섹션으로 컬렉션을 스크롤합니다.
    func scrollToMatch(_ match: VoiceNoteSearchMatch) {
        guard case .script(let sectionIndex) = match.location else { return }
        let indexPath = IndexPath(item: sectionIndex, section: 0)
        guard dataSource.itemIdentifier(for: indexPath) != nil else { return }
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
    }
}

// MARK: - Layout

private extension VoiceNoteScriptViewController {
    static func makeLayout(viewModel: VoiceNoteViewModel) -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, environment in
            var config = UICollectionLayoutListConfiguration(appearance: .plain)
            config.backgroundColor = .clear
            config.showsSeparators = false
            config.headerMode = .supplementary

            let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)

            for item in section.boundarySupplementaryItems {
                item.pinToVisibleBounds = false
                item.edgeSpacing = NSCollectionLayoutEdgeSpacing(
                    leading: nil, top: .fixed(22),
                    trailing: nil, bottom: nil
                )
                item.contentInsets = NSDirectionalEdgeInsets(
                    top: 0, leading: 20, bottom: 0, trailing: 20
                )
            }

            let isShowingSkeleton: Bool = switch viewModel.voiceNote.analysisState {
            case .pending, .transcribing: true
            default: false
            }

            section.contentInsets = NSDirectionalEdgeInsets(
                top: 12, leading: 20, bottom: 0, trailing: 20
            )
            section.interGroupSpacing = isShowingSkeleton ? Constant.scriptCellSpacing : 16

            return section
        }
    }
}

// MARK: - DataSource

private extension VoiceNoteScriptViewController {
    var isShowingSkeleton: Bool {
        switch viewModel.voiceNote.analysisState {
        case .pending, .transcribing:
            return true
        case .transcribed, .summarizing, .regenerating, .completed,
             .transcriptionFailed, .summarizationFailed:
            return false
        }
    }

    func makeDataSource() -> UICollectionViewDiffableDataSource<Section, Item> {
        let scriptCellReg = UICollectionView.CellRegistration<UICollectionViewCell, Item> { [weak self] cell, _, item in
            guard let self, case .script(let index) = item else { return }
            let section = viewModel.scriptSections[index]
            let isHighlighted = viewModel.playingSectionIndex == index

            let focusedRange: NSRange? = {
                guard let match = self.viewModel.currentMatch,
                      case .script(let sectionIndex) = match.location,
                      sectionIndex == index else { return nil }
                return match.range
            }()

            cell.contentConfiguration = ScriptContentConfiguration(
                sectionIndex: index,
                timestamp: section.timestamp,
                text: section.text,
                isHighlighted: isHighlighted,
                isEditing: viewModel.editingMode == .script,
                searchQuery: viewModel.searchQuery,
                currentMatchRange: focusedRange,
                onTextEdited: { [weak self] sectionIndex, text in
                    self?.viewModel.updateScriptSection(sectionIndex: sectionIndex, text: text)
                },
                onTextHeightChanged: { [weak self] in
                    guard let self else { return }
                    UIView.performWithoutAnimation {
                        self.collectionView.collectionViewLayout.invalidateLayout()
                    }
                }
            )
        }

        let scriptSkeletonCellReg = UICollectionView.CellRegistration<UICollectionViewCell, Item> { cell, _, item in
            guard case .scriptSkeleton(_, let beginOffset) = item else { return }
            cell.contentConfiguration = ScriptSkeletonContentConfiguration(beginOffset: beginOffset)
        }

        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            switch item {
            case .script:
                return collectionView.dequeueConfiguredReusableCell(using: scriptCellReg, for: indexPath, item: item)
            case .scriptSkeleton:
                return collectionView.dequeueConfiguredReusableCell(
                    using: scriptSkeletonCellReg, for: indexPath, item: item
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
        ) { header, _, _ in
            header.configure(title: "스크립트")
        }
    }

    func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.scripts])

        let items: [Item] = if isShowingSkeleton {
            (0 ..< 30).map { idx in
                .scriptSkeleton(index: idx, beginOffset: Double(idx % 3) * 0.2)
            }
        } else {
            viewModel.scriptSections.indices.map { Item.script(index: $0) }
        }

        snapshot.appendItems(items, toSection: .scripts)
        snapshot.reconfigureItems(items)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    func reconfigureScripts() {
        var snapshot = dataSource.snapshot()
        let scriptItems = snapshot.itemIdentifiers(inSection: .scripts)
        guard !scriptItems.isEmpty else { return }
        snapshot.reconfigureItems(scriptItems)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Observations

private extension VoiceNoteScriptViewController {
    func observeTranscriptSections() {
        withObservationTracking {
            _ = viewModel.voiceNote.transcript?.sections
        } onChange: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.applySnapshot()
                self.observeTranscriptSections()
            }
        }
    }

    func observeAnalysisState() {
        withObservationTracking {
            _ = viewModel.voiceNote.analysisState
        } onChange: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.collectionView.collectionViewLayout.invalidateLayout()
                self.applySnapshot()
                self.observeAnalysisState()
            }
        }
    }

    func observePlayingParagraph() {
        withObservationTracking {
            _ = viewModel.playingSectionIndex
        } onChange: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.reconfigureScripts()
                self.observePlayingParagraph()
            }
        }
    }

    func observeEditingMode() {
        withObservationTracking {
            _ = viewModel.editingMode
        } onChange: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.reconfigureScripts()
                self.observeEditingMode()
            }
        }
    }

    func observeSearchState() {
        withObservationTracking {
            _ = viewModel.searchQuery
            _ = viewModel.currentMatchIndex
            _ = viewModel.currentPage
        } onChange: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.reconfigureScripts()
                self.observeSearchState()
            }
        }
    }
}

// MARK: - UICollectionViewDelegate

extension VoiceNoteScriptViewController {
    override func collectionView(
        _ collectionView: UICollectionView,
        shouldSelectItemAt indexPath: IndexPath
    ) -> Bool {
        viewModel.editingMode != .script && !viewModel.searchMode
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        defer { collectionView.deselectItem(at: indexPath, animated: false) }
        guard case .script(let index) = dataSource.itemIdentifier(for: indexPath) else { return }
        let timestamp = viewModel.scriptSections[index].timestamp
        viewModel.scriptTimestampTapped(timestamp)
    }
}

// MARK: - Section / Item

extension VoiceNoteScriptViewController {
    enum Section: Int, CaseIterable {
        case scripts
    }

    enum Item: Hashable {
        case script(index: Int)
        case scriptSkeleton(index: Int, beginOffset: CFTimeInterval)
    }
}
