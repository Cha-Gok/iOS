import UIKit

public final class TextFieldView: UIView {
    // MARK: - Properties

    var isEdit: Bool
    var title: String
    var subTitle: String
    private let placeholder: String

    var onConfirm: ((String) -> Void)?
    var onCancel: (() -> Void)?

    // MARK: - UI Components

    private let containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fill
        stack.spacing = Constant.alertTopAndBottomContentSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let topContentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .gray950
        return label
    }()

    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .gray800
        label.numberOfLines = 0
        return label
    }()

    private lazy var textField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.backgroundColor = .white.withAlphaComponent(0.5)
        tf.layer.cornerRadius = 12
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.gray300.cgColor
        tf.placeholder = placeholder
        tf.font = Typography.body1.font
        tf.textColor = .gray950
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        tf.clearButtonMode = .whileEditing

        // Left Padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.leftView = paddingView
        tf.leftViewMode = .always

        tf.delegate = self
        tf.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        return tf
    }()

    private let bottomContentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = Constant.alertSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let cancelButton: GlassButton = .close("취소")
    private lazy var confirmButton: GlassButton = .primary(isEdit ? "수정" : "추가")

    // MARK: - Initializer

    init(isEdit: Bool, title: String, subTitle: String, placeholder: String) {
        self.isEdit = isEdit
        self.title = title
        self.subTitle = subTitle
        self.placeholder = placeholder
        super.init(frame: .zero)
        setup()
        setupConstraints()
        setupActions()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let superview else { return }

        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: superview.centerXAnchor),
            centerYAnchor.constraint(equalTo: superview.centerYAnchor, constant: -100), // Keyboard offset
            widthAnchor.constraint(equalTo: superview.widthAnchor, multiplier: Constant.alertMultiplierWidth)
        ])

        // Auto focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.textField.becomeFirstResponder()
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = Constant.cornerRadius

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = Constant.shadowOpacity
        layer.shadowOffset = CGSize(width: Constant.shadowOffsetWidth, height: Constant.shadowOffsetHeight)
        layer.shadowRadius = Constant.cornerRadius
    }
}

// MARK: - Setup

private extension TextFieldView {
    func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .point200.withAlphaComponent(0.9) // More opaque for readability
        layer.borderWidth = Constant.borderWidth
        layer.borderColor = UIColor.gray600.cgColor

        headerLabel.setTypography(text: title, style: .title2)
        bodyLabel.setTypography(text: subTitle, style: .body1)

        confirmButton.isEnabled = false

        addSubview(containerStack)
        containerStack.addArrangedSubview(topContentStack)
        containerStack.addArrangedSubview(bottomContentStack)

        topContentStack.addArrangedSubview(headerLabel)
        topContentStack.addArrangedSubview(bodyLabel)
        topContentStack.addArrangedSubview(textField)

        bottomContentStack.addArrangedSubview(cancelButton)
        bottomContentStack.addArrangedSubview(confirmButton)
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(
                equalTo: topAnchor,
                constant: Constant.alertTopAndBottomValueForTopContent
            ),
            containerStack.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: Constant.alertLeftAndRightValueForTopContent
            ),
            containerStack.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -Constant.alertLeftAndRightValueForTopContent
            ),
            containerStack.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -Constant.alertTopAndBottomValueForBottomContent
            ),

            textField.heightAnchor.constraint(equalToConstant: 48),
            bottomContentStack.heightAnchor.constraint(equalToConstant: Constant.alertBottomContentHeight)
        ])
    }

    func setupActions() {
        cancelButton.addAction(UIAction { [weak self] _ in
            self?.onCancel?()
            self?.textField.text = ""
        }, for: .touchUpInside)

        confirmButton.addAction(UIAction { [weak self] _ in
            guard let text = self?.textField.text, !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            self?.onConfirm?(text)
            self?.textField.text = ""
        }, for: .touchUpInside)
    }

    @objc
    func textFieldDidChange() {
        let text = textField.text ?? ""
        confirmButton.isEnabled = !text.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

// MARK: - Public API

public extension TextFieldView {
    func configure(
        isEdit: Bool,
        name: String? = nil,
        title: String? = nil,
        subTitle: String? = nil
    ) {
        self.isEdit = isEdit
        if let title { self.title = title }
        if let subTitle { self.subTitle = subTitle }

        headerLabel.setTypography(text: self.title, style: .title2)
        bodyLabel.setTypography(text: self.subTitle, style: .body1)

        if isEdit {
            textField.text = name
            confirmButton.setTitle("수정", for: .normal)
            confirmButton.isEnabled = !(name?.isEmpty ?? true)
        } else {
            textField.text = ""
            confirmButton.setTitle("추가", for: .normal)
            confirmButton.isEnabled = false
        }
    }
}

// MARK: - UITextFieldDelegate

extension TextFieldView: UITextFieldDelegate {
    public func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)

        return updatedText.count <= 20
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if confirmButton.isEnabled {
            guard let text = textField.text else { return true }
            onConfirm?(text)
        }
        return true
    }
}
