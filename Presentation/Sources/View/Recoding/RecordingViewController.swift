import Domain
import UIKit

public final class RecordingViewController: ViewController {
    private let viewModel: RecordingViewModel

    // MARK: - UI Components

    private lazy var cancelButton: GlassButton = {
        let button = GlassButton()
        button.configure(
            type: .plain(),
            viewModel.state.cancelTitle,
            typography: .title2,
            backgroundColor: .color(.clear),
            foregroundColor: UIColor.gray950
        )

        return button
    }()

    private lazy var completeButton: GlassButton = {
        let button = GlassButton()
        button.configure(
            type: .plain(),
            viewModel.state.completeTitle,
            typography: .title2,
            backgroundColor: .color(.clear),
            foregroundColor: UIColor.point800
        )

        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .gray950
        label.setTypography(style: .header2)

        return label
    }()

    private let timestampLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .gray800
        label.setTypography(style: .subtitle2)

        return label
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .gray950
        label.setTypography(style: .header1)

        return label
    }()

    private lazy var recordButton: GlassButton = {
        let button = GlassButton()
        button.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold),
            forImageIn: .normal
        )
        button.configure(
            type: .clearGlass(),
            nil,
            typography: .body1,
            image: .init(imageName: recordButtonSymbolName, type: .system)
        )
        button.setCapsuleCornerRadius()
        button.addAction(UIAction { [weak self] _ in
            self?.viewModel.send(.recordButtonTapped)
        }, for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization

    public init(viewModel: RecordingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    // MARK: - View Life Cycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.send(.viewDidAppear)
    }

    override public func updateProperties() {
        super.updateProperties()
        updateNavigationBarAppearance(isTransparent: true)
        chagokBackgroundView.amplitude.value = viewModel.state.amplitude
        titleLabel.setTypography(text: viewModel.state.title, style: .header2)
        timestampLabel.setTypography(text: viewModel.state.displayStartDate, style: .subtitle2)
        durationLabel.setTypography(text: viewModel.state.displayDuration, style: .header1)
        recordButton.setImage(UIImage(systemName: recordButtonSymbolName), for: .normal)
    }

    // MARK: - Private Methods

    private func setupNavigation() {
        viewModel.showCancelAlert = { [weak self] in
            guard let self else { return }
            viewModel.alertCoordinator?.presentAlert(environment: .recordingCancel, delegate: self)
        }
        
        viewModel.showCompleteAlert = { [weak self] in
            guard let self else { return }
            viewModel.alertCoordinator?.presentAlert(environment: .recordingComplete, delegate: self)
        }

        cancelButton.addAction(UIAction { [weak self] _ in
            self?.viewModel.send(.openCancelAlertButtonTapped)
        }, for: .touchUpInside)

        completeButton.addAction(UIAction { [weak self] _ in
            self?.viewModel.send(.openCompleteAlertButtonTapped)
        }, for: .touchUpInside)

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: completeButton)

        for item in [navigationItem.leftBarButtonItem, navigationItem.rightBarButtonItem] {
            item?.hidesSharedBackground = true
        }
    }

    private func setupUI() {
        for item in [titleLabel, durationLabel, recordButton, timestampLabel] {
            item.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(item)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 180),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            timestampLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            timestampLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timestampLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 160),
            timestampLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            timestampLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            durationLabel.topAnchor.constraint(equalTo: timestampLabel.bottomAnchor, constant: 120),
            durationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            durationLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            durationLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.widthAnchor.constraint(equalToConstant: 120),
            recordButton.heightAnchor.constraint(equalToConstant: 60),
            recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            recordButton.topAnchor.constraint(greaterThanOrEqualTo: durationLabel.bottomAnchor, constant: 48)
        ])
    }

    private var recordButtonSymbolName: String {
        switch viewModel.state.recordingState {
        case .idle:
            return "mic.fill"
        case .recording:
            return "pause.fill"
        case .paused:
            return "play.fill"
        }
    }
}


// MARK: - Delegate

extension RecordingViewController: ChaGokAlertButtonTappedDelegate {
    public func recordingCancelCloseButtonTapped(_ alertVC: ChaGokAlertViewController) {
        alertVC.dismiss(animated: true)
    }
    
    public func recordingCancelPrimaryButtonTapped(_ alertVC: ChaGokAlertViewController) {
        alertVC.dismiss(animated: true) { [weak self] in
            self?.viewModel.send(.cancelButtonTapped)
        }
    }
    
    public func recordingCompleteCloseButtonTapped(_ alertVC: ChaGokAlertViewController) {
        alertVC.dismiss(animated: true)
    }
    
    public func recordingCompletePrimaryButtonTapped(_ alertVC: ChaGokAlertViewController) {
        alertVC.dismiss(animated: true) { [weak self] in
            self?.viewModel.send(.finishButtonTapped)
        }
    }
}
