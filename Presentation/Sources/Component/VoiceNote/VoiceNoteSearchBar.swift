import UIKit

/// 보이스 노트 내부 검색 모드에서 사용하는 검색 입력 바.
/// 좌측 다크 글래스 입력 영역(검색 아이콘 + 텍스트 필드) + 우측 원형 닫기 버튼으로 구성됩니다.
public final class VoiceNoteSearchBar: UIView {
    public var onQueryChanged: ((String) -> Void)?
    public var onClose: (() -> Void)?
    public var onReturn: (() -> Void)?

    // MARK: - Search area

    private let searchShadowContainer = UIView()
    private let searchBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let searchTintView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 9 / 255, green: 0, blue: 38 / 255, alpha: 0.2)
        view.isUserInteractionEnabled = false
        return view
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView(image: .search)
        imageView.tintColor = UIColor.gray600
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let textField: TypographyTextField = {
        let field = TypographyTextField(typography: .body1)
        field.textColor = .white
        field.tintColor = .white
        field.returnKeyType = .search
        field.clearButtonMode = .never
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.spellCheckingType = .no
        var placeholderAttrs = Typography.body1.textAttributes
        placeholderAttrs[.foregroundColor] = UIColor.gray600
        field.attributedPlaceholder = NSAttributedString(string: "검색", attributes: placeholderAttrs)
        return field
    }()

    // MARK: - Close button

    private let closeShadowContainer = UIView()
    private let closeBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let closeTintView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 9 / 255, green: 0, blue: 38 / 255, alpha: 0.2)
        view.isUserInteractionEnabled = false
        return view
    }()

    private let closeButton: UIButton = {
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .white
        return button
    }()

    // MARK: - Init

    public init() {
        super.init(frame: .zero)
        setupUI()
        setupActions()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - First responder

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

    // MARK: - Layout

    override public func layoutSubviews() {
        super.layoutSubviews()
        searchShadowContainer.layer.shadowPath = UIBezierPath(
            roundedRect: searchShadowContainer.bounds,
            cornerRadius: 20
        ).cgPath
        closeShadowContainer.layer.shadowPath = UIBezierPath(
            ovalIn: closeShadowContainer.bounds
        ).cgPath
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .clear

        addSubview(searchShadowContainer)
        addSubview(closeShadowContainer)

        configureShadow(on: searchShadowContainer)
        searchShadowContainer.addSubview(searchBlurView)
        searchBlurView.contentView.addSubview(searchTintView)
        searchBlurView.contentView.addSubview(iconView)
        searchBlurView.contentView.addSubview(textField)

        searchBlurView.layer.cornerRadius = 20
        searchBlurView.layer.masksToBounds = true
        searchBlurView.layer.borderWidth = 1
        searchBlurView.layer.borderColor = UIColor.gray600.cgColor

        configureShadow(on: closeShadowContainer)
        closeShadowContainer.addSubview(closeBlurView)
        closeBlurView.contentView.addSubview(closeTintView)
        closeShadowContainer.addSubview(closeButton)

        closeBlurView.layer.cornerRadius = 23
        closeBlurView.layer.masksToBounds = true
        closeBlurView.layer.borderWidth = 1
        closeBlurView.layer.borderColor = UIColor(white: 0.953, alpha: 1).cgColor

        setupConstraints()
    }

    private func configureShadow(on view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.16
        view.layer.shadowOffset = CGSize(width: 2, height: 2)
        view.layer.shadowRadius = 16
    }

    private func setupConstraints() {
        for subview in [
            searchShadowContainer, closeShadowContainer,
            searchBlurView, searchTintView, iconView, textField,
            closeBlurView, closeTintView, closeButton
        ] {
            subview.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 46),

            searchShadowContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            searchShadowContainer.topAnchor.constraint(equalTo: topAnchor),
            searchShadowContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            searchShadowContainer.trailingAnchor.constraint(equalTo: closeShadowContainer.leadingAnchor, constant: -12),

            searchBlurView.topAnchor.constraint(equalTo: searchShadowContainer.topAnchor),
            searchBlurView.leadingAnchor.constraint(equalTo: searchShadowContainer.leadingAnchor),
            searchBlurView.trailingAnchor.constraint(equalTo: searchShadowContainer.trailingAnchor),
            searchBlurView.bottomAnchor.constraint(equalTo: searchShadowContainer.bottomAnchor),

            searchTintView.topAnchor.constraint(equalTo: searchBlurView.contentView.topAnchor),
            searchTintView.leadingAnchor.constraint(equalTo: searchBlurView.contentView.leadingAnchor),
            searchTintView.trailingAnchor.constraint(equalTo: searchBlurView.contentView.trailingAnchor),
            searchTintView.bottomAnchor.constraint(equalTo: searchBlurView.contentView.bottomAnchor),

            iconView.leadingAnchor.constraint(equalTo: searchBlurView.contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: searchBlurView.contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            textField.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: searchBlurView.contentView.trailingAnchor, constant: -16),
            textField.topAnchor.constraint(equalTo: searchBlurView.contentView.topAnchor),
            textField.bottomAnchor.constraint(equalTo: searchBlurView.contentView.bottomAnchor),

            closeShadowContainer.topAnchor.constraint(equalTo: topAnchor),
            closeShadowContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            closeShadowContainer.widthAnchor.constraint(equalToConstant: 46),
            closeShadowContainer.heightAnchor.constraint(equalToConstant: 46),

            closeBlurView.topAnchor.constraint(equalTo: closeShadowContainer.topAnchor),
            closeBlurView.leadingAnchor.constraint(equalTo: closeShadowContainer.leadingAnchor),
            closeBlurView.trailingAnchor.constraint(equalTo: closeShadowContainer.trailingAnchor),
            closeBlurView.bottomAnchor.constraint(equalTo: closeShadowContainer.bottomAnchor),

            closeTintView.topAnchor.constraint(equalTo: closeBlurView.contentView.topAnchor),
            closeTintView.leadingAnchor.constraint(equalTo: closeBlurView.contentView.leadingAnchor),
            closeTintView.trailingAnchor.constraint(equalTo: closeBlurView.contentView.trailingAnchor),
            closeTintView.bottomAnchor.constraint(equalTo: closeBlurView.contentView.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: closeShadowContainer.topAnchor),
            closeButton.leadingAnchor.constraint(equalTo: closeShadowContainer.leadingAnchor),
            closeButton.trailingAnchor.constraint(equalTo: closeShadowContainer.trailingAnchor),
            closeButton.bottomAnchor.constraint(equalTo: closeShadowContainer.bottomAnchor)
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
        container.backgroundColor = UIColor(red: 0.02, green: 0.01, blue: 0.08, alpha: 1)
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
