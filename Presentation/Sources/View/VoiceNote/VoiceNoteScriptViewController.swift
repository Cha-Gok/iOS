import Observation
import UIKit

final class VoiceNoteScriptViewController: UIViewController {
    private let viewModel: VoiceNoteViewModel

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.keyboardDismissMode = .interactive
        cv.delegate = self
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
        registerKeyboardObservers()
        observeTranscriptSections()
        observePlayingParagraph()
        observeEditingMode()
        observeSearchState()
    }

    /// 지정한 매치 위치의 스크립트 섹션으로 컬렉션을 스크롤합니다.
    func scrollToMatch(_ match: VoiceNoteSearchMatch) {
        guard case .script(let sectionIndex) = match.location else { return }
        let indexPath = IndexPath(item: sectionIndex, section: 0)
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

private extension VoiceNoteScriptViewController {
    func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, environment in
            var config = UICollectionLayoutListConfiguration(appearance: .plain)
            config.backgroundColor = .clear
            config.showsSeparators = false
            config.headerMode = .supplementary

            let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)

            for item in section.boundarySupplementaryItems {
                item.pinToVisibleBounds = false
                item.edgeSpacing = NSCollectionLayoutEdgeSpacing(
                    leading: nil, top: .fixed(32),
                    trailing: nil, bottom: nil
                )
            }

            section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 0, trailing: 0)
            section.interGroupSpacing = 16

            return section
        }
    }
}

// MARK: - DataSource

private extension VoiceNoteScriptViewController {
    func makeDataSource() -> UICollectionViewDiffableDataSource<Section, Item> {
        let scriptCellReg = UICollectionView.CellRegistration<UICollectionViewCell, Item> { [weak self] cell, _, item in
            guard let self, case .script(let index) = item else { return }
            let section = viewModel.scriptSections[index]
            let isHighlighted = viewModel.playingSectionIndex == index

            let focusedRange: NSRange? = {
                guard let match = viewModel.currentMatch,
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
                onTextEdited: { [weak self] sIdx, text in
                    self?.viewModel.updateScriptSection(sectionIndex: sIdx, text: text)
                },
                onTextHeightChanged: { [weak self] in
                    guard let self else { return }
                    UIView.performWithoutAnimation {
                        self.collectionView.collectionViewLayout.invalidateLayout()
                    }
                }
            )
        }

        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: collectionView
        ) { col, indexPath, item in
            col.dequeueConfiguredReusableCell(using: scriptCellReg, for: indexPath, item: item)
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
        ) { header, _, _ in
            header.configure(title: "스크립트")
        }
    }

    func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.scripts])
        let scriptItems = viewModel.scriptSections.indices.map { Item.script(index: $0) }
        snapshot.appendItems(scriptItems, toSection: .scripts)
        snapshot.reconfigureItems(scriptItems)
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

// MARK: - Keyboard

private extension VoiceNoteScriptViewController {
    func registerKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
}

extension VoiceNoteScriptViewController {
    @objc
    fileprivate func keyboardWillChangeFrame(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = view.convert(frameValue.cgRectValue, from: nil)
        let overlap = max(0, collectionView.frame.maxY - keyboardFrame.minY)
        applyKeyboardInset(overlap, userInfo: userInfo)
        scrollActiveResponderVisible()
    }

    @objc
    fileprivate func keyboardWillHide(_ notification: Notification) {
        applyKeyboardInset(0, userInfo: notification.userInfo)
    }

    private func applyKeyboardInset(_ bottom: CGFloat, userInfo: [AnyHashable: Any]?) {
        let duration = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.25
        let curveRaw = (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt)
            ?? UInt(UIView.AnimationCurve.easeInOut.rawValue)
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.collectionView.contentInset.bottom = bottom
            self.collectionView.verticalScrollIndicatorInsets.bottom = bottom
        }
    }

    private func scrollActiveResponderVisible() {
        guard let responder = collectionView.activeFirstResponder() else { return }
        let frameInCollection = responder.convert(responder.bounds, to: collectionView)
        collectionView.scrollRectToVisible(frameInCollection.insetBy(dx: 0, dy: -16), animated: true)
    }
}

private extension UIView {
    func activeFirstResponder() -> UIView? {
        if isFirstResponder { return self }
        for subview in subviews {
            if let found = subview.activeFirstResponder() { return found }
        }
        return nil
    }
}

// MARK: - UICollectionViewDelegate

extension VoiceNoteScriptViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        viewModel.editingMode != .script && !viewModel.searchMode
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
    }
}
