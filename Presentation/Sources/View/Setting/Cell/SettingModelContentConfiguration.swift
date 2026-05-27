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

    /// 각 카드 뷰를 한 번만 생성하여 참조를 보관합니다.
    private var cardViews: [(data: ChaGokModelState, view: UIView)] = []

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
            cardsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            cardsStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])

        // 서브뷰 생성은 apply()에서 처리합니다.
    }

    // MARK: - Apply

    private func apply(configuration: UIContentConfiguration) {
        guard let config = configuration as? SettingModelContentConfiguration else { return }

        // 기존 카드 뷰들을 제거하고 새롭게 추가 (dummySpacer는 제외)
        for arrangedSubview in cardsStackView.arrangedSubviews {
            if arrangedSubview !== dummySpacer {
                arrangedSubview.removeFromSuperview()
            }
        }
        cardViews.removeAll()

        for model in config.models {
            let card = makeModelCard(model: model)
            cardsStackView.addArrangedSubview(card)
            cardViews.append((data: model, view: card))
        }
    }

    // MARK: - Card View Factory

    private func makeModelCard(model: ChaGokModelState) -> UIView {
        let innerVerticalStack = UIStackView()
        innerVerticalStack.axis = .vertical
        innerVerticalStack.spacing = 8
        innerVerticalStack.alignment = .leading

        // 3. Title Horizontal Stack (Icon + Title)
        let titleHorizontalStack = UIStackView()
        titleHorizontalStack.axis = .horizontal
        titleHorizontalStack.spacing = 8
        titleHorizontalStack.alignment = .center

        // Left Icon (Storage drive next to the model title)
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        iconImageView.image = UIImage(systemName: "externaldrive", withConfiguration: iconConfig)
        iconImageView.tintColor = .gray950
        iconImageView.contentMode = .scaleAspectFit

        // Title Label
        let titleLabel = UILabel()
        titleLabel.setTypography(text: model.title, style: .subtitle2)
        titleLabel.textColor = .gray950

        titleHorizontalStack.addArrangedSubview(iconImageView)
        titleHorizontalStack.addArrangedSubview(titleLabel)

        // Description Label (Under the icon + title stack)
        let descLabel = UILabel()
        descLabel.setTypography(text: model.subTitle, style: .caption)
        descLabel.textColor = .gray750
        descLabel.numberOfLines = 0

        innerVerticalStack.addArrangedSubview(titleHorizontalStack)
        innerVerticalStack.addArrangedSubview(descLabel)

        // Right Control (Button or ActivityIndicator)
        let rightControlContainer = UIView()
        rightControlContainer.translatesAutoresizingMaskIntoConstraints = false

        let actionButton = UIButton(type: .system)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        let actionConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)

        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true

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
            rightControlContainer.heightAnchor.constraint(equalToConstant: 24)
        ])

        // Configure State
        let actionType: SettingModelContentConfiguration.ActionType
        switch model.status.storage {
        case .downloaded:
            actionButton.isHidden = false
            actionButton.setImage(UIImage(systemName: "trash", withConfiguration: actionConfig), for: .normal)
            actionButton.tintColor = .danger
            actionType = .delete
        case .downloading:
            actionButton.isHidden = true
            activityIndicator.startAnimating()
            actionType = .download // Disabled anyway, but needed for compilation
        default:
            actionButton.isHidden = false
            actionButton.setImage(
                UIImage(systemName: "square.and.arrow.down", withConfiguration: actionConfig),
                for: .normal
            )
            actionButton.tintColor = .point800
            actionType = .download
        }

        actionButton.addAction(UIAction { [weak self] _ in
            guard let config = self?.configuration as? SettingModelContentConfiguration else { return }
            config.action?(model.model, actionType)
        }, for: .touchUpInside)

        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20)
        ])

        let containerStack = UIStackView(arrangedSubviews: [innerVerticalStack, rightControlContainer])
        containerStack.axis = .horizontal
        containerStack.spacing = 16
        containerStack.alignment = .center
        containerStack.layoutMargins = .init(top: 16, left: 16, bottom: 16, right: 16)
        containerStack.isLayoutMarginsRelativeArrangement = true

        // Apply Premium Glass Effect
        let tintColor: UIColor = .point200.withAlphaComponent(0.2)
        containerStack.applyGlassEffect(tintColor: tintColor)

        return containerStack
    }
}
