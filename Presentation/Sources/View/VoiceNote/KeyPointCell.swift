import UIKit

// MARK: - KeyPointContentConfiguration

struct KeyPointContentConfiguration: UIContentConfiguration {
    var number: Int = 0
    var text: String = ""

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

    private let badgeView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.backgroundColor = UIColor.point600
        stack.layer.cornerRadius = 20
        return stack
    }()

    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let textLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.gray800
        label.numberOfLines = 0
        return label
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
        backgroundColor = UIColor.gray100
        layer.cornerRadius = Constant.cornerRadius

        badgeView.addArrangedSubview(badgeLabel)
        addSubview(badgeView)
        addSubview(textLabel)

        for subview in [badgeView, textLabel] {
            subview.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            badgeView.widthAnchor.constraint(equalToConstant: 24),
            badgeView.heightAnchor.constraint(equalToConstant: 24),
            badgeView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            badgeView.centerYAnchor.constraint(equalTo: centerYAnchor),

            textLabel.leadingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: 8),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    // MARK: - Apply

    private func apply(configuration: UIContentConfiguration) {
        guard let config = configuration as? KeyPointContentConfiguration else { return }
        badgeLabel.text = "\(config.number)"
        textLabel.setTypography(text: config.text, style: .body1)
    }
}
