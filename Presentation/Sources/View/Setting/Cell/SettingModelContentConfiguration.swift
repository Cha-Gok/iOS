import Domain
import UIKit

// MARK: - SettingModelContentConfiguration

struct SettingModelContentConfiguration: UIContentConfiguration {
    enum ActionType {
        case download
        case delete
    }

    let title: String
    let models: [ChaGokModelState]
    var action: ((ChaGokModel, ActionType) -> Void)?

    func makeContentView() -> any UIView & UIContentView {
        SettingModelContent(configuration: self)
    }

    func updated(for state: any UIConfigurationState) -> Self {
        self
    }
}

// MARK: - SettingModelContent

final class SettingModelContent: UIView, UIContentView {
    var configuration: any UIContentConfiguration {
        didSet { apply(configuration: configuration) }
    }

    // MARK: - Components

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .gray950
        if let config = configuration as? SettingModelContentConfiguration {
            label.setTypography(text: config.title, style: .title2)
        }
        return label
    }()

    private let cardsStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    /// 빈 배열일 때 UIStackView 높이 무한대 크래쉬 방지용 더미 뷰
    private let dummySpacer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 0).isActive = true
        return view
    }()

    // MARK: - Initialize

    init(configuration: any UIContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        setup()
        apply(configuration: configuration)
    }

    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - Setup

    private func setup() {
        addSubview(titleLabel)
        addSubview(cardsStackView)
        cardsStackView.addArrangedSubview(dummySpacer)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            cardsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            cardsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            cardsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])

        let bottomConstraint = cardsStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        bottomConstraint.priority = UILayoutPriority(999)
        bottomConstraint.isActive = true

        // 서브뷰 생성은 apply()에서 처리합니다.
    }

    // MARK: - Apply

    private func apply(configuration: UIContentConfiguration) {
        guard let config = configuration as? SettingModelContentConfiguration else { return }

        let activeCardViews = cardsStackView.arrangedSubviews.compactMap { $0 as? SettingModelCardView }

        if activeCardViews.count == config.models.count {
            for (index, modelState) in config.models.enumerated() {
                activeCardViews[index].update(modelState: modelState) { [weak self] targetModel, actionType in
                    guard let self else { return }
                    if let currentConfig = self.configuration as? SettingModelContentConfiguration {
                        currentConfig.action?(targetModel, actionType)
                    }
                }
            }
        } else {
            for arrangedSubview in cardsStackView.arrangedSubviews {
                if arrangedSubview !== dummySpacer {
                    arrangedSubview.removeFromSuperview()
                }
            }

            for modelState in config.models {
                let card = SettingModelCardView()
                card.update(modelState: modelState) { [weak self] targetModel, actionType in
                    guard let self else { return }
                    if let currentConfig = self.configuration as? SettingModelContentConfiguration {
                        currentConfig.action?(targetModel, actionType)
                    }
                }
                cardsStackView.addArrangedSubview(card)
            }
        }
    }
}

// MARK: - SettingModelCardView

final class SettingModelCardView: UIStackView {
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        iv.image = UIImage(systemName: "externaldrive", withConfiguration: iconConfig)
        iv.tintColor = .gray950
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel = UILabel()
    private let descLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray750
        label.numberOfLines = 0
        return label
    }()

    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private var currentModel: ChaGokModel = .none
    private var currentActionType: SettingModelContentConfiguration.ActionType = .download
    private var onAction: ((ChaGokModel, SettingModelContentConfiguration.ActionType) -> Void)?

    init() {
        super.init(frame: .zero)
        setup()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        axis = .horizontal
        spacing = 16
        alignment = .center
        layoutMargins = .init(top: 16, left: 16, bottom: 16, right: 16)
        isLayoutMarginsRelativeArrangement = true

        let innerVerticalStack = UIStackView()
        innerVerticalStack.axis = .vertical
        innerVerticalStack.spacing = 8
        innerVerticalStack.alignment = .leading

        let titleHorizontalStack = UIStackView()
        titleHorizontalStack.axis = .horizontal
        titleHorizontalStack.spacing = 8
        titleHorizontalStack.alignment = .center

        titleLabel.textColor = .gray950

        titleHorizontalStack.addArrangedSubview(iconImageView)
        titleHorizontalStack.addArrangedSubview(titleLabel)

        innerVerticalStack.addArrangedSubview(titleHorizontalStack)
        innerVerticalStack.addArrangedSubview(descLabel)

        let rightControlContainer = UIView()
        rightControlContainer.translatesAutoresizingMaskIntoConstraints = false
        rightControlContainer.addSubview(actionButton)
        rightControlContainer.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            actionButton.centerXAnchor.constraint(equalTo: rightControlContainer.centerXAnchor),
            actionButton.centerYAnchor.constraint(equalTo: rightControlContainer.centerYAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 24),
            actionButton.heightAnchor.constraint(equalToConstant: 24),

            activityIndicator.centerXAnchor.constraint(equalTo: rightControlContainer.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: rightControlContainer.centerYAnchor),

            rightControlContainer.widthAnchor.constraint(equalToConstant: 24),
            rightControlContainer.heightAnchor.constraint(equalToConstant: 24),

            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20)
        ])

        addArrangedSubview(innerVerticalStack)
        addArrangedSubview(rightControlContainer)

        actionButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            onAction?(currentModel, currentActionType)
        }, for: .touchUpInside)

        let tintColor: UIColor = .point200.withAlphaComponent(0.2)
        applyGlassEffect(tintColor: tintColor)
    }

    func update(
        modelState: ChaGokModelState,
        onAction: @escaping (ChaGokModel, SettingModelContentConfiguration.ActionType) -> Void
    ) {
        currentModel = modelState.model
        self.onAction = onAction

        titleLabel.setTypography(text: modelState.title, style: .subtitle2)
        descLabel.setTypography(text: modelState.subTitle, style: .caption)

        let actionConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        switch modelState.status.storage {
        case .downloaded:
            actionButton.isHidden = false
            activityIndicator.stopAnimating()
            actionButton.setImage(UIImage(systemName: "trash", withConfiguration: actionConfig), for: .normal)
            actionButton.tintColor = .danger
            currentActionType = .delete
        case .downloading:
            actionButton.isHidden = true
            activityIndicator.startAnimating()
            currentActionType = .download
        default:
            actionButton.isHidden = false
            activityIndicator.stopAnimating()
            actionButton.setImage(
                UIImage(systemName: "square.and.arrow.down", withConfiguration: actionConfig),
                for: .normal
            )
            actionButton.tintColor = .point800
            currentActionType = .download
        }
    }
}
