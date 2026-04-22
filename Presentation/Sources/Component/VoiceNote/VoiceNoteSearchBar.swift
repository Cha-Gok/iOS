import UIKit

/// 보이스 노트 내부 검색 모드에서 사용하는 검색 입력 바.
/// 좌측 검색 아이콘 + 중앙 텍스트 필드 + 우측 닫기(X) 버튼으로 구성됩니다.
public final class VoiceNoteSearchBar: UIView {
    public var onQueryChanged: ((String) -> Void)?
    public var onClose: (() -> Void)?
    public var onReturn: (() -> Void)?

    private let iconView: UIImageView = {
        let imageView = UIImageView(image: .search)
        imageView.tintColor = UIColor.gray750
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let textField: TypographyTextField = {
        let field = TypographyTextField(typography: .body1)
        field.textColor = UIColor.gray950
        field.returnKeyType = .search
        field.clearButtonMode = .never
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.spellCheckingType = .no
        return field
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = UIColor.gray750
        return button
    }()

    public init() {
        super.init(frame: .zero)
        setupUI()
        setupActions()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    @discardableResult
    override public func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }

    @discardableResult
    override public func resignFirstResponder() -> Bool {
        textField.resignFirstResponder()
    }

    /// 외부에서 쿼리 텍스트를 초기화할 때 사용합니다.
    public func setQuery(_ query: String) {
        textField.text = query
    }

    private func setupUI() {
        backgroundColor = UIColor.gray100
        layer.cornerRadius = 20
        layer.borderColor = UIColor.gray300.cgColor
        layer.borderWidth = 1

        for subview in [iconView, textField, closeButton] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subview)
        }

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            textField.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            textField.topAnchor.constraint(equalTo: topAnchor),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor),

            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),

            heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupActions() {
        textField.addAction(UIAction { [weak self] _ in
            self?.onQueryChanged?(self?.textField.text ?? "")
        }, for: .editingChanged)

        textField.addAction(UIAction { [weak self] _ in
            self?.onReturn?()
        }, for: .editingDidEndOnExit)

        closeButton.addAction(UIAction { [weak self] _ in
            self?.onClose?()
        }, for: .touchUpInside)
    }
}

#if DEBUG
    #Preview {
        let bar = VoiceNoteSearchBar()
        bar.setQuery("검색어")
        let container = UIView()
        container.backgroundColor = .white
        bar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bar)
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            bar.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            bar.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }
#endif
