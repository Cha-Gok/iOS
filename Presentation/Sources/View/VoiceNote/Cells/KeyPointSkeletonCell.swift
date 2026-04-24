import UIKit

// MARK: - KeyPointSkeletonContentConfiguration

struct KeyPointSkeletonContentConfiguration: UIContentConfiguration {
    var number: Int = 0
    var beginOffset: CFTimeInterval = 0

    func makeContentView() -> UIView & UIContentView {
        KeyPointSkeletonContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> KeyPointSkeletonContentConfiguration {
        self
    }
}

// MARK: - KeyPointSkeletonContentView

final class KeyPointSkeletonContentView: UIView, UIContentView {
    var configuration: UIContentConfiguration {
        didSet { apply(configuration: configuration) }
    }

    // MARK: - UI Components

    private let badgeLabel: TypographyLabel = {
        let label = TypographyLabel(typography: .title3, alignment: .center)
        label.textColor = .white
        label.backgroundColor = UIColor.point600
        label.layer.cornerRadius = Constant.keyPointBadgeSize / 2
        label.clipsToBounds = true
        return label
    }()

    private let skeletonLine = SkeletonLineView()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Constant.keyPointContentSpacing
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: Constant.keyPointCardVerticalPadding,
            leading: Constant.keyPointCardHorizontalPadding,
            bottom: Constant.keyPointCardVerticalPadding,
            trailing: Constant.keyPointCardHorizontalPadding
        )
        stack.backgroundColor = UIColor.gray100
        stack.layer.cornerRadius = Constant.cornerRadius
        return stack
    }()

    // MARK: - Init

    init(configuration: UIContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        setupUI()
        apply(configuration: configuration)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - Setup

    private func setupUI() {
        contentStack.addArrangedSubview(badgeLabel)
        contentStack.addArrangedSubview(skeletonLine)
        addSubview(contentStack)

        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            badgeLabel.widthAnchor.constraint(equalToConstant: Constant.keyPointBadgeSize),
            badgeLabel.heightAnchor.constraint(equalToConstant: Constant.keyPointBadgeSize),

            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Apply

    private func apply(configuration: UIContentConfiguration) {
        guard let config = configuration as? KeyPointSkeletonContentConfiguration else { return }
        badgeLabel.text = "\(config.number)"
        skeletonLine.startAnimating(beginOffset: config.beginOffset)
    }
}

// MARK: - Preview

#Preview {
    let preview: UIView = {
        let configs = [
            KeyPointSkeletonContentConfiguration(number: 1, beginOffset: 0.0),
            KeyPointSkeletonContentConfiguration(number: 2, beginOffset: 0.2),
            KeyPointSkeletonContentConfiguration(number: 3, beginOffset: 0.4)
        ]

        let stack = UIStackView(arrangedSubviews: configs.map { $0.makeContentView() })
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.backgroundColor = .systemPink
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }()

    preview
}
