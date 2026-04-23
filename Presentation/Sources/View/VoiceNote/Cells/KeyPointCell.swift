import UIKit

// MARK: - KeyPointContentConfiguration

struct KeyPointContentConfiguration: UIContentConfiguration {
    var number: Int = 0
    var text: String = ""
    var searchQuery: String = ""
    var currentMatchRange: NSRange?

    func makeContentView() -> UIView & UIContentView {
        KeyPointContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> KeyPointContentConfiguration {
        self
    }
}

// MARK: - KeyPointContentView

final class KeyPointContentView: UIView, UIContentView {
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

    private let textLabel: TypographyLabel = {
        let label = TypographyLabel(typography: .body1)
        label.textColor = UIColor.gray800
        label.numberOfLines = 0
        return label
    }()

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
        contentStack.addArrangedSubview(textLabel)
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
        guard let config = configuration as? KeyPointContentConfiguration else { return }
        badgeLabel.text = "\(config.number)"
        if config.searchQuery.isEmpty {
            textLabel.text = config.text
        } else {
            textLabel.attributedText = config.text.highlighted(
                query: config.searchQuery,
                baseAttributes: Typography.body1.textAttributes,
                highlightBackgroundColor: UIColor.point700,
                focusedRange: config.currentMatchRange,
                focusedHighlightBackgroundColor: .systemRed
            )
        }
    }
}

// MARK: - Preview

#Preview {
    let firstConfig = KeyPointContentConfiguration(
        number: 1,
        text: "한 줄짜리 핵심 포인트 예시입니다."
    )
    let secondConfig = KeyPointContentConfiguration(
        number: 2,
        text: "여러 줄로 길게 이어지는 핵심 포인트 예시입니다. 텍스트가 길어져도 뱃지는 수직 중앙에 정렬되어 유지됩니다."
    )

    let firstCell = KeyPointContentView(configuration: firstConfig)
    let secondCell = KeyPointContentView(configuration: secondConfig)

    let stack = UIStackView(arrangedSubviews: [firstCell, secondCell])
    stack.axis = .vertical
    stack.spacing = 6
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
}
