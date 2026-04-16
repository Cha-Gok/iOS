import UIKit

final class TextFieldView: UIView {
    // MARK: - Properties

    var field: Field

    // 키보드 상태 변화를 알리기 위한 콜백
    var onEditingDidBegin: (() -> Void)?
    var onEditingDidEnd: (() -> Void)?

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
        // UITextField는 한 줄 입력 요소이므로 줄간격(paragraphStyle)이나
        // baselineOffset이 들어가면 자체 수직 정렬(Center Y) 계산과 충돌해 텍스트가 살짝 아래로 처집니다.
        // 따라서 폰트, 글자색상, 자간(kern)만 명시적으로 넣어줍니다.
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
        setup()
    }

    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - LifeCycle

    override func layoutSubviews() {
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

    override func updateProperties() {
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
    }

    // MARK: - Setup

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .point200.withAlphaComponent(0.2)
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
        container.setCustomSpacing(24, after: textField)
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

    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !field.text.isEmpty
    }

    @objc
    private func textFieldDidChange() {
        field.text = textField.text ?? ""
        updatePlaceholderVisibility()
    }
}

// MARK: - Observable 구조

extension TextFieldView {
    @Observable
    final class Field {
        var mode: Mode
        var title: String
        var subTitle: String
        var placeHolder: String
        var text: String

        var trimmedText: String {
            text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var isSubmitEnabled: Bool {
            !trimmedText.isEmpty
        }

        init(mode: Mode, title: String, subTitle: String, placeHolder: String, text: String = "") {
            self.mode = mode
            self.title = title
            self.subTitle = subTitle
            self.placeHolder = placeHolder
            self.text = text
        }
    }

    enum Mode {
        case create
        case edit
    }
}

// MARK: TextField Delegate

extension TextFieldView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        onEditingDidBegin?()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        onEditingDidEnd?()
    }
}
