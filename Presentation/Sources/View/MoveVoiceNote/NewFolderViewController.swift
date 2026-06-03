import UIKit

public final class NewFolderViewController: UIViewController, Alertable {
    private let viewModel: NewFolderViewModel

    public init(viewModel: NewFolderViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.setTypography(text: "새 폴더 만들기", style: .title3)
        label.textColor = .gray950
        return label
    }()

    private lazy var folderNameTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.textColor = .gray950
        textField.attributedPlaceholder = NSAttributedString(
            string: "사용자가 설정하는 폴더이름",
            attributes: [.foregroundColor: UIColor.gray600]
        )
        return textField
    }()

    private lazy var textFieldContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .gray200
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var cancelButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "취소"
        configuration.background.cornerRadius = 20
        configuration.baseBackgroundColor = .gray300
        configuration.baseForegroundColor = .gray950
        configuration.contentInsets = .zero
        return UIButton(configuration: configuration)
    }()

    private lazy var createButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "만들기"
        configuration.background.cornerRadius = 20
        configuration.baseBackgroundColor = .point600
        configuration.baseForegroundColor = .gray950
        configuration.contentInsets = .zero
        return UIButton(configuration: configuration)
    }()

    private let spacerView = UIView()

    private lazy var buttonStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [cancelButton, createButton])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        return stack
    }()

    override public var preferredContentSize: CGSize {
        get {
            view.layoutIfNeeded()
            let height = view.systemLayoutSizeFitting(
                CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            ).height
            return CGSize(width: view.bounds.width, height: height)
        }
        set { super.preferredContentSize = newValue }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        addActions()
    }

    override public func updateProperties() {
        super.updateProperties()
        guard let message = viewModel.state.errorMessage else { return }
        viewModel.clearErrorMessage()
        showAlert(message: message)
    }

    private func setupUI() {
        view.backgroundColor = .gray100

        textFieldContainer.addSubview(folderNameTextField)
        folderNameTextField.translatesAutoresizingMaskIntoConstraints = false

        for subview in [titleLabel, textFieldContainer, buttonStack, spacerView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subview)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 44),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            titleLabel.heightAnchor.constraint(equalToConstant: 24),

            textFieldContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 26),
            textFieldContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textFieldContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textFieldContainer.heightAnchor.constraint(equalToConstant: 40),

            folderNameTextField.leadingAnchor.constraint(equalTo: textFieldContainer.leadingAnchor, constant: 12),
            folderNameTextField.trailingAnchor.constraint(equalTo: textFieldContainer.trailingAnchor, constant: -12),
            folderNameTextField.centerYAnchor.constraint(equalTo: textFieldContainer.centerYAnchor),

            buttonStack.topAnchor.constraint(equalTo: textFieldContainer.bottomAnchor, constant: 20),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 46),

            spacerView.topAnchor.constraint(equalTo: buttonStack.bottomAnchor),
            spacerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            spacerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            spacerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func addActions() {
        cancelButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            viewModel.send(.view(.cancelButtonTapped))
        }, for: .touchUpInside)

        createButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            viewModel.send(.view(.createButtonTapped(name: folderNameTextField.text ?? "")))
        }, for: .touchUpInside)
    }
}
