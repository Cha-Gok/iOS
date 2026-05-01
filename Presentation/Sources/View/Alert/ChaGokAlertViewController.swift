import Domain
import UIKit

public final class ChaGokAlertViewController: UIViewController {
    private var cancelButton: GlassButton = .init()
    private let primaryButton: GlassButton = .init()
    private var alertView: AlertView?
    private var textFieldView: TextFieldView?
    private var languagePickerAlert: LanguagePickerAlert?
    private weak var currentContentView: UIView?
    public weak var delegate: ChaGokAlertButtonTappedDelegate?
    public var selectedLanguage: Language? {
        vm.selectedLanguage
    }

    // MARK: - Initialize

    private let vm: ChaGokAlertViewModel

    public init(vm: ChaGokAlertViewModel) {
        self.vm = vm
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        isModalInPresentation = true
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

    /// Componenet 중 AlertView를 초기화 합니다.
    private func setAlertView(state: ChaGokAlertViewModel.AlertState, subTitle: String) {
        let alertView = AlertView(
            title: state.header.title,
            subTitle: subTitle,
            closeButton: cancelButton,
            primaryButton: primaryButton
        )
        self.alertView = alertView
        attachContentView(alertView)
    }

    /// Componenet 중 LanguagePickerAlert 를 초기화 합니다.
    private func setLanguagePickerAlertView(
        state: ChaGokAlertViewModel.AlertState,
        language: Language
    ) {
        let languagePicker = LanguagePicker(
            selected: language,
            axis: .horizontal,
            showAlert: true
        )
        vm.setSelectedLanguage(language)
        languagePicker.onLanguageChanged = { [weak self] updatedLanguage in
            self?.vm.setSelectedLanguage(updatedLanguage)
        }
        let languagePickerAlert = LanguagePickerAlert(
            title: state.header.title,
            languagePicker: languagePicker,
            closeButton: cancelButton,
            primaryButton: primaryButton
        )
        self.languagePickerAlert = languagePickerAlert
        attachContentView(languagePickerAlert)
    }

    /// Componenet 중 TextFieldView 를 초기화 합니다.
    private func setTextFieldAlertView(
        state: ChaGokAlertViewModel.AlertState,
        field: TextFieldView.Field,
        subTitle: String
    ) {
        field.title = state.header.title
        field.subTitle = subTitle
        let textFieldView = TextFieldView(
            field: field,
            cancelButton: cancelButton,
            primaryButton: primaryButton
        )
        self.textFieldView = textFieldView
        attachContentView(textFieldView, needsWidthConstraint: true, respectKeyboard: true)
    }

    private func attachContentView(
        _ contentView: UIView,
        needsWidthConstraint: Bool = false,
        respectKeyboard: Bool = false
    ) {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)
        currentContentView = contentView

        var constraints: [NSLayoutConstraint] = []

        if respectKeyboard {
            let containerGuide = UILayoutGuide()
            view.addLayoutGuide(containerGuide)

            constraints.append(contentsOf: [
                containerGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                containerGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                containerGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                containerGuide.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

                contentView.centerXAnchor.constraint(equalTo: containerGuide.centerXAnchor),
                contentView.centerYAnchor.constraint(equalTo: containerGuide.centerYAnchor),
                contentView.topAnchor.constraint(greaterThanOrEqualTo: containerGuide.topAnchor, constant: 20),
                contentView.bottomAnchor.constraint(lessThanOrEqualTo: containerGuide.bottomAnchor, constant: -20)
            ])
        } else {
            constraints.append(contentsOf: [
                contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }

        if needsWidthConstraint {
            constraints.append(contentView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8))
        }
        NSLayoutConstraint.activate(constraints)
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
            setAlertView(state: state, subTitle: subTitle)
        case .languagePicker(let language):
            setLanguagePickerAlertView(state: state, language: language)
        case .textField(let field, let subTitle):
            setTextFieldAlertView(state: state, field: field, subTitle: subTitle)
        }
    }
}
