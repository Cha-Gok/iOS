import Domain
import UIKit

public final class RecordingViewController: UIViewController {
    private let viewModel: RecordingViewModel

    // MARK: - UI Components

    private let backgroundView: RecordingBackgroundView = .init()

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

    private lazy var recordButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 30
        button.clipsToBounds = true
        button.backgroundColor = .gray50
        button.tintColor = .gray950
        button.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold),
            forImageIn: .normal
        )
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

    override public func updateProperties() {
        super.updateProperties()
        backgroundView.updateValue(viewModel.state.amplitude)
        titleLabel.setTypography(text: viewModel.state.title, style: .header2)
        timestampLabel.setTypography(text: viewModel.state.displayStartDate, style: .subtitle2)
        durationLabel.setTypography(text: viewModel.state.displayDuration, style: .header1)
        recordButton.setImage(UIImage(systemName: recordButtonSymbolName), for: .normal)
    }

    // MARK: - Private Methods

    private func setupNavigation() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak self] _ in
                self?.viewModel.send(.cancelButtonTapped)
            }
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .done,
            primaryAction: UIAction { [weak self] _ in
                self?.viewModel.send(.finishButtonTapped)
            }
        )
    }

    private func setupUI() {
        for item in [backgroundView, titleLabel, durationLabel, recordButton, timestampLabel] {
            item.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(item)
        }

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
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
