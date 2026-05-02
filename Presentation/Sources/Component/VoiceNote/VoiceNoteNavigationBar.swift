import UIKit

@MainActor
final class VoiceNoteNavigationBar {
    typealias EditingMode = VoiceNoteViewModel.EditingMode

    // MARK: - Events

    var onBack: (() -> Void)?
    var onEditCancel: (() -> Void)?
    var onDoneTitle: ((String) -> Void)?
    var onDoneScript: (() -> Void)?
    var onMove: (() -> Void)?
    var onEditScript: (() -> Void)?
    var onDelete: (() -> Void)?
    var onTapTitle: (() -> Void)?
    var onSearchEnter: (() -> Void)?
    var onSearchQuery: ((String) -> Void)?
    var onSearchClose: (() -> Void)?

    // MARK: - UI Components

    private let titleContainerView = TitleContainerView()
    private let searchBar = VoiceNoteSearchBar()

    private let backItem = UIBarButtonItem(image: .chevronLeft)
    private let editCancelItem = UIBarButtonItem(image: .cornerUpLeft)
    private let doneItem = UIBarButtonItem(title: "완료")
    private let moreItem = UIBarButtonItem(image: .moreVertical)
    private let searchItem = UIBarButtonItem(image: .search)

    // MARK: - State

    private var currentEditingMode: EditingMode?
    private var lastSearchMode = false

    var titleText: String {
        get { titleContainerView.text ?? "" }
        set { titleContainerView.text = newValue }
    }

    var isEditingTitle: Bool {
        titleContainerView.isEditingTitle
    }

    // MARK: - Init

    init() {
        setupBarItems()
        setupTitleContainer()
        setupSearchBar()
    }

    // MARK: - Public API

    /// 네비게이션 바 상태를 적용한다.
    /// - Returns: 검색 모드가 전환(진입/해제)되었으면 `true`
    @discardableResult
    func apply(
        to navigationItem: UINavigationItem,
        title: String,
        editingMode: EditingMode? = nil,
        searchMode: Bool = false,
        hasScriptEdits: Bool = false
    ) -> Bool {
        currentEditingMode = editingMode
        let didToggleSearch = searchMode != lastSearchMode
        lastSearchMode = searchMode

        switch editingMode {
        case .title:
            if !titleContainerView.isEditingTitle {
                titleContainerView.text = title
                titleContainerView.setEditing(true)
            }
        case .script:
            titleContainerView.isHidden = true
            editCancelItem.tintColor = hasScriptEdits ? UIColor.gray950 : UIColor.gray600
        case nil:
            titleContainerView.setEditing(false)
            titleContainerView.text = title
            titleContainerView.isHidden = false
        }

        if searchMode {
            navigationItem.hidesBackButton = true
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItems = []
            navigationItem.titleView = searchBar
        } else {
            navigationItem.hidesBackButton = false
            navigationItem.titleView = titleContainerView
            switch editingMode {
            case .title:
                navigationItem.leftBarButtonItem = backItem
                navigationItem.rightBarButtonItems = [doneItem]
            case .script:
                navigationItem.leftBarButtonItem = editCancelItem
                navigationItem.rightBarButtonItems = [doneItem]
            case nil:
                navigationItem.leftBarButtonItem = backItem
                navigationItem.rightBarButtonItems = [moreItem, searchItem]
            }
        }

        if didToggleSearch {
            if searchMode {
                searchBar.becomeFirstResponder()
            } else {
                searchBar.setQuery("")
                searchBar.resignFirstResponder()
            }
        }

        return didToggleSearch
    }
}

// MARK: - Setup

private extension VoiceNoteNavigationBar {
    func setupBarItems() {
        for item in [backItem, editCancelItem, doneItem, moreItem, searchItem] {
            item.hidesSharedBackground = true
        }
        backItem.tintColor = UIColor.gray950
        doneItem.tintColor = UIColor.point800
        [moreItem, searchItem].forEach { $0.tintColor = .white }

        backItem.primaryAction = UIAction { [weak self] _ in
            self?.onBack?()
        }
        editCancelItem.primaryAction = UIAction { [weak self] _ in
            self?.onEditCancel?()
        }
        doneItem.primaryAction = UIAction { [weak self] _ in
            guard let self else { return }
            switch currentEditingMode {
            case .title: onDoneTitle?(titleContainerView.text ?? "")
            case .script: onDoneScript?()
            case nil: break
            }
        }
        moreItem.menu = UIMenu(children: [
            UIAction(title: "기록 이동하기") { [weak self] _ in
                self?.onMove?()
            },
            UIAction(title: "편집하기") { [weak self] _ in
                self?.onEditScript?()
            },
            UIAction(title: "삭제하기", attributes: .destructive) { [weak self] _ in
                self?.onDelete?()
            }
        ])
        searchItem.primaryAction = UIAction { [weak self] _ in
            self?.onSearchEnter?()
        }
    }

    func setupTitleContainer() {
        titleContainerView.onTapTitle = { [weak self] in
            self?.onTapTitle?()
        }
        titleContainerView.onCommit = { [weak self] text in
            self?.onDoneTitle?(text)
        }
    }

    func setupSearchBar() {
        searchBar.onReturn = { [weak self] query in
            self?.onSearchQuery?(query)
        }
        searchBar.onClose = { [weak self] in
            self?.onSearchClose?()
        }
    }
}

// MARK: - TitleContainerView

/// 네비게이션 바의 titleView로 사용하기 위한 컨테이너 뷰.
///
/// intrinsicContentSize의 width를 최대로 반환하여
/// 좌측 ~ 우측 바 아이템 사이의 가용 영역을 전부 차지한다.
/// 표시용 Label과 편집용 TextField를 함께 소유하며,
/// `setEditing(_:)`으로 두 상태를 전환한다.
private final class TitleContainerView: UIView {
    var onTapTitle: (() -> Void)?
    var onCommit: ((String) -> Void)?

    private let titleLabel: TypographyLabel = {
        let label = TypographyLabel(typography: .header2)
        label.textColor = UIColor.gray950
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.isUserInteractionEnabled = true
        return label
    }()

    private let titleField: TypographyTextField = {
        let field = TypographyTextField(typography: .header2)
        field.textColor = UIColor.gray950
        field.tintColor = UIColor.gray950
        field.returnKeyType = .done
        field.isHidden = true
        return field
    }()

    /// setEditing으로 진입한 편집 상태 여부.
    /// resignFirstResponder가 편집 종료 콜백을 재발화시키는 것을 막기 위해 사용한다.
    private(set) var isEditingTitle = false

    var text: String? {
        get { titleField.text }
        set {
            titleLabel.text = newValue
            titleField.text = newValue
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override var intrinsicContentSize: CGSize {
        let height = subviews.first(where: { !$0.isHidden })?.intrinsicContentSize.height
            ?? super.intrinsicContentSize.height
        return CGSize(width: UIView.layoutFittingExpandedSize.width, height: height)
    }

    func setEditing(_ isEditing: Bool) {
        isEditingTitle = isEditing
        if isEditing {
            titleLabel.isHidden = true
            titleField.isHidden = false
            titleField.becomeFirstResponder()
        } else {
            titleField.resignFirstResponder()
            titleLabel.isHidden = false
            titleField.isHidden = true
        }
    }

    private func setup() {
        titleField.delegate = self

        let tap = UITapGestureRecognizer(target: self, action: #selector(titleTapped))
        titleLabel.addGestureRecognizer(tap)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleField.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)
        addSubview(titleField)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleField.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleField.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleField.topAnchor.constraint(equalTo: topAnchor),
            titleField.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc
    private func titleTapped() {
        onTapTitle?()
    }
}

// MARK: - TitleContainerView + UITextFieldDelegate

extension TitleContainerView: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        onTapTitle?()
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onCommit?(textField.text ?? "")
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard isEditingTitle else { return }
        onCommit?(textField.text ?? "")
    }
}

// MARK: - Preview

#Preview {
    let viewController = ViewController()
    viewController.loadViewIfNeeded()

    let appearance = UINavigationBarAppearance()
    appearance.configureWithTransparentBackground()
    appearance.backgroundEffect = UIBlurEffect(style: .dark)
    viewController.navigationItem.standardAppearance = appearance
    viewController.navigationItem.compactAppearance = appearance
    viewController.navigationItem.scrollEdgeAppearance = appearance

    let navigationBar = VoiceNoteNavigationBar()
    navigationBar.apply(to: viewController.navigationItem, title: "음성 메모 제목")

    return UINavigationController(rootViewController: viewController)
}
