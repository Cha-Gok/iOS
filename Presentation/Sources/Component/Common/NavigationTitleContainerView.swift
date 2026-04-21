import UIKit

/// 네비게이션 바의 titleView로 사용하기 위한 컨테이너 뷰.
///
/// intrinsicContentSize의 width를 최대로 반환하여
/// 좌측 ~ 우측 바 아이템 사이의 가용 영역을 전부 차지한다.
/// 표시용 Label과 편집용 TextField를 함께 소유하며,
/// `setEditing(_:)`으로 두 상태를 전환한다.
final class NavigationTitleContainerView: UIView {
    // MARK: - Events

    var onTapTitle: (() -> Void)?
    var onShouldBeginEditing: (() -> Void)?
    var onCommit: ((String) -> Void)?

    // MARK: - UI Components

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

    // MARK: - State

    /// setEditing으로 진입한 편집 상태 여부.
    /// resignFirstResponder가 편집 종료 콜백을 재발화시키는 것을 막기 위해 사용한다.
    private var isEditingTitle = false

    var text: String? {
        get { titleField.text }
        set {
            titleLabel.text = newValue
            titleField.text = newValue
        }
    }

    // MARK: - Initialize

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

    // MARK: - Public API

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

    // MARK: - Setup

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
            titleField.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @objc
    private func titleTapped() {
        onTapTitle?()
    }
}

// MARK: - UITextFieldDelegate

extension NavigationTitleContainerView: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        onShouldBeginEditing?()
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
