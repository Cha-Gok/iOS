import UIKit

public final class TextFieldView: UIView {
    // MARK: - Properties

    var field: Field

    // MARK: - Componenet

    private let container: UIStackView = {
        let c = UIStackView()
        c.translatesAutoresizingMaskIntoConstraints = false
        c.axis = .vertical
        c.spacing = 12
        return c
    }()

    private lazy var titleLabel: UILabel = {
        let t = UILabel()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.setTypography(text: field.title, style: .title2, textAlignment: .center)
        t.textColor = .gray950
        return t
    }()

    private lazy var subTitleLabel: UILabel = {
        let t = UILabel()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.setTypography(text: field.subTitle, style: .body2, textAlignment: .center)
        t.textColor = .gray950
        t.numberOfLines = 0
        return t
    }()

    private lazy var textField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.backgroundColor = .gray100
        tf.layer.cornerRadius = 8
        tf.textColor = .gray950
        tf.font = Typography.body1.font
        tf.defaultTextAttributes = [
            .font: Typography.body1.font,
            .foregroundColor: UIColor.gray950,
            .kern: Typography.body1.letterSpacing
        ]
        tf.delegate = self
        tf.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.rightViewMode = .always
        return tf
    }()

    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setTypography(text: field.placeHolder, style: .body1)
        label.textColor = .gray600
        label.numberOfLines = 0
        return label
    }()

    private lazy var textCount: UILabel = {
        let text = UILabel()
        text.translatesAutoresizingMaskIntoConstraints = false
        text.setTypography(text: field.textCountLabel, style: .label)
        text.textColor = UIColor.gray750
        text.numberOfLines = 0
        text.setContentCompressionResistancePriority(.required, for: .vertical)
        return text
    }()

    private let bottomContainer: UIStackView = {
        let c = UIStackView()
        c.translatesAutoresizingMaskIntoConstraints = false
        c.axis = .horizontal
        c.spacing = 8

        return c
    }()

    private let cancelButton: GlassButton
    private let primaryButton: GlassButton

    // MARK: - Initialize

    init(
        field: Field,
        cancelButton: GlassButton,
        primaryButton: GlassButton
    ) {
        self.field = field
        self.cancelButton = cancelButton
        self.primaryButton = primaryButton
        super.init(frame: .zero)
        applyGlassEffect(tintColor: .gray200.withAlphaComponent(0.2))
        setup()
    }

    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - LifeCycle

    override public func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = Constant.shadowOpacity
        layer.shadowOffset = CGSize(width: Constant.shadowOffsetWidth, height: Constant.shadowOffsetHeight)
        layer.shadowRadius = Constant.cornerRadius
        layer.shadowPath =
            UIBezierPath(
                roundedRect: bounds,
                cornerRadius: Constant.cornerRadius
            ).cgPath
    }

    override public func updateProperties() {
        super.updateProperties()
        titleLabel.setTypography(text: field.title, style: .title2, textAlignment: .center)
        subTitleLabel.setTypography(text: field.subTitle, style: .body2, textAlignment: .center)
        placeholderLabel.setTypography(text: field.placeHolder, style: .body1)

        if textField.text != field.text {
            textField.text = field.text
        }

        switch field.mode {
        case .create:
            primaryButton.configuration?.title = "만들기"
        case .edit:
            primaryButton.configuration?.title = "수정하기"
        }
        primaryButton.isEnabled = field.isSubmitEnabled
        updatePlaceholderVisibility()
        // error Message
        updateErrorMessageLabel()
    }

    // MARK: - Setup

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = Constant.cornerRadius
        layer.borderColor = UIColor.gray600.cgColor
        layer.borderWidth = Constant.borderWidth
        setupConstraint()
        setupStyle()
    }

    private func setupConstraint() {
        bottomContainer.addArrangedSubview(cancelButton)
        bottomContainer.addArrangedSubview(primaryButton)
        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(subTitleLabel)
        container.addArrangedSubview(textField)
        container.setCustomSpacing(8, after: textField)
        container.addArrangedSubview(textCount)
        container.setCustomSpacing(24, after: textCount)
        container.addArrangedSubview(bottomContainer)
        addSubview(container)
        textField.addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: 32),
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -32),
            textField.heightAnchor.constraint(equalToConstant: 48),
            placeholderLabel.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            placeholderLabel.leadingAnchor.constraint(equalTo: textField.leadingAnchor, constant: 12),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: textField.trailingAnchor, constant: -12),
            cancelButton.heightAnchor.constraint(equalToConstant: 46),
            primaryButton.heightAnchor.constraint(equalToConstant: 46)
        ])
    }

    private func setupStyle() {
        cancelButton.setShadow(true)
        cancelButton.setCapsuleCornerRadius()
        primaryButton.setShadow(true)
        primaryButton.setCapsuleCornerRadius()
        updatePlaceholderVisibility()
    }

    @objc
    private func textFieldDidChange() {
        field.text = textField.text ?? ""
        field.errorMessage = nil
        textCount.setTypography(text: field.textCountLabel, style: .label)
        textCount.textColor = field.text.count >= 50 ? .danger : .gray750
        updatePlaceholderVisibility()
    }
}

// MARK: - Update Method

extension TextFieldView {
    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !field.text.isEmpty
    }

    private func updateErrorMessageLabel() {
        if let errorMessage = field.errorMessage {
            textCount.setTypography(text: errorMessage, style: .label)
            textCount.textColor = .danger
        } else {
            textCount.setTypography(text: field.textCountLabel, style: .label)
            textCount.textColor = field.text.count >= 50 ? .danger : .gray750
        }
    }
}

// MARK: - Observable 구조

extension TextFieldView {
    @Observable
    public final class Field: Sendable {
        var mode: Mode
        var title: String
        var subTitle: String
        var placeHolder: String
        var text: String
        var errorMessage: String?

        var isSubmitEnabled: Bool {
            !text.isEmpty
        }

        var textCountLabel: String {
            "\(text.count)/\(50)"
        }

        var textCountOverCheck: Bool {
            text.count > 50
        }

        public init(
            mode: Mode,
            title: String,
            subTitle: String,
            placeHolder: String,
            text: String = "",
            errorMessage: String?
        ) {
            self.mode = mode
            self.title = title
            self.subTitle = subTitle
            self.placeHolder = placeHolder
            self.text = text
            self.errorMessage = errorMessage
        }
    }

    public enum Mode {
        case create
        case edit
    }
}

// MARK: TextField Delegate

extension TextFieldView: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    public func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let currentText = textField.text as NSString? else { return true }
        let updatedText = currentText.replacingCharacters(in: range, with: string)
        return updatedText.count <= 50
    }
}
