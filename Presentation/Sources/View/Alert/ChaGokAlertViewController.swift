import UIKit

public final class ChaGokAlertViewController: UIViewController {
    private var cancelButton: GlassButton = .init()
    private let primaryButton: GlassButton = .init()
    private var alertView: AlertView?
    private var textFieldView: TextFieldView?
    private var languagePickerAlert: LanguagePickerAlert?
    private weak var currentContentView: UIView?
    public weak var delegate: ChaGokAlertButtonTappedDelegate?
    
    // MARK: - Initialize
    
    private let vm: ChaGokAlertViewModel
    
    public init(vm: ChaGokAlertViewModel) {
        self.vm = vm
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    // MARK: - LifeCycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupActions()
        render(vm.state)
    }
    
    // MARK: - setup
    private func setup() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    }

    private func setupActions() {
        cancelButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                vm.didTapCancel(delegate: delegate, alertVC: self)
            },
            for: .touchUpInside
        )

        primaryButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                vm.didTapPrimary(delegate: delegate, alertVC: self)
            },
            for: .touchUpInside
        )
    }
}

// MARK: Component 초기화

extension ChaGokAlertViewController {
    private func render(_ state: ChaGokAlertViewModel.AlertState) {
        cancelButton.apply(state.cancelButtonStyle)
        primaryButton.apply(state.primaryButtonStyle)

        currentContentView?.removeFromSuperview()

        switch state.bodyStyle {
        case .basic(let subTitle):
            let alertView = AlertView(
                title: state.header.title,
                subTitle: subTitle,
                closeButton: cancelButton,
                primaryButton: primaryButton
            )
            self.alertView = alertView
            attachContentView(alertView)
        case .languagePicker(let picker):
            let languagePickerAlert = LanguagePickerAlert(
                title: state.header.title,
                languagePicker: picker,
                closeButton: cancelButton,
                primaryButton: primaryButton
            )
            self.languagePickerAlert = languagePickerAlert
            attachContentView(languagePickerAlert)
        case .textField(let field, let subTitle):
            field.title = state.header.title
            field.subTitle = subTitle
            let textFieldView = TextFieldView(
                field: field,
                cancelButton: cancelButton,
                primaryButton: primaryButton
            )
            self.textFieldView = textFieldView
            attachContentView(textFieldView, needsWidthConstraint: true)
        }
    }

    private func attachContentView(_ contentView: UIView, needsWidthConstraint: Bool = false) {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)
        currentContentView = contentView

        var constraints: [NSLayoutConstraint] = [
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        if needsWidthConstraint {
            constraints.append(contentView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8))
        }
        NSLayoutConstraint.activate(constraints)
    }
}
