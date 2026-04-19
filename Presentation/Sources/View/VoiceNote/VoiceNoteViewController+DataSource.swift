import UIKit

// MARK: - CollectionView Layout & DataSource

extension VoiceNoteViewController {
    func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { sectionIndex, environment in
            var config = UICollectionLayoutListConfiguration(appearance: .plain)
            config.backgroundColor = .clear
            config.showsSeparators = false
            config.headerMode = Section(rawValue: sectionIndex) == .metadata ? .none : .supplementary

            let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)
            let topInset: CGFloat = Section(rawValue: sectionIndex) == .metadata ? 24 : 12
            section.contentInsets = NSDirectionalEdgeInsets(top: topInset, leading: 20, bottom: 32, trailing: 20)
            switch Section(rawValue: sectionIndex) {
            case .keyPoints: section.interGroupSpacing = 6
            case .scripts: section.interGroupSpacing = 16
            default: break
            }
            section.boundarySupplementaryItems.forEach { $0.pinToVisibleBounds = false }
            return section
        }
    }

    func makeDataSource() -> UICollectionViewDiffableDataSource<Section, Item> {
        let metadataCellReg = UICollectionView.CellRegistration<UICollectionViewCell, Item> { [weak self] cell, _, _ in
            cell.contentConfiguration = MetadataContentConfiguration(
                folderName: self?.viewModel.folderName ?? "",
                date: self?.viewModel.metadataText1 ?? "",
                duration: self?.viewModel.metadataText2 ?? ""
            )
        }

        let keyPointCellReg = UICollectionView.CellRegistration<UICollectionViewCell, Item> { cell, _, item in
            guard case .keyPoint(let number, let text) = item else { return }
            cell.contentConfiguration = KeyPointContentConfiguration(number: number, text: text)
        }

        let keywordsCellReg = UICollectionView.CellRegistration<KeywordsCell, Item> { [weak self] cell, _, _ in
            cell.contentConfiguration = KeywordsContentConfiguration(
                keywords: self?.viewModel.keywords ?? []
            )
        }

        let scriptCellReg = UICollectionView.CellRegistration<UICollectionViewCell, Item> { [weak self] cell, _, item in
            guard let self, case .script(let index) = item else { return }
            let section = viewModel.scriptSections[index]
            let isHighlighted = viewModel.playingSectionIndex == index

            cell.contentConfiguration = ScriptContentConfiguration(
                sectionIndex: index,
                timestamp: section.formattedTimestamp,
                timestampSeconds: section.timestamp,
                text: section.text,
                isHighlighted: isHighlighted,
                isEditing: viewModel.editingMode == .script,
                onTextEdited: { [weak self] sIdx, text in
                    self?.viewModel.updateScriptSection(sectionIndex: sIdx, text: text)
                },
                onTimestampTapped: { [weak self] time in
                    self?.viewModel.scriptTimestampTapped(time)
                }
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
            case .script:
                return col.dequeueConfiguredReusableCell(using: scriptCellReg, for: indexPath, item: item)
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
        ) { header, _, indexPath in
            guard let section = Section(rawValue: indexPath.section),
                  let title = section.headerTitle else { return }

            if section == .keyPoints {
                let chip = ChipView(icon: UIImage(systemName: "arrow.clockwise"), text: "재생성")
                header.configure(title: title, trailingView: chip)
            } else {
                header.configure(title: title)
            }
        }
    }

    func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)

        let metadataItems: [Item] = [.metadata]
        let keyPointItems = viewModel.keyPoints.map { Item.keyPoint(number: $0.number, text: $0.text) }
        let keywordItems: [Item] = [.keywords]
        let scriptItems = viewModel.scriptSections.indices.map { Item.script(index: $0) }

        snapshot.appendItems(metadataItems, toSection: .metadata)
        snapshot.appendItems(keyPointItems, toSection: .keyPoints)
        snapshot.appendItems(keywordItems, toSection: .keywords)
        snapshot.appendItems(scriptItems, toSection: .scripts)

        snapshot.reconfigureItems(metadataItems + keywordItems + scriptItems)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - Section / Item

extension VoiceNoteViewController {
    enum Section: Int, CaseIterable {
        case metadata
        case keyPoints
        case keywords
        case scripts

        var title: String? {
            switch self {
            case .keyPoints: return "AI 요약"
            case .keywords: return "키워드"
            case .scripts: return "스크립트"
            default: return nil
            }
        }

        var headerTitle: String? {
            switch self {
            case .keyPoints: return "핵심 포인트"
            case .keywords: return "키워드"
            case .scripts: return "스크립트"
            default: return nil
            }
        }
    }

    enum Item: Hashable {
        case metadata
        case keyPoint(number: Int, text: String)
        case keywords
        case script(index: Int)
    }
}
