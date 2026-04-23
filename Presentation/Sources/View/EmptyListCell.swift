import UIKit

struct EmptyContentConfiguration: UIContentConfiguration {
    let message: String
    func makeContentView() -> any UIView & UIContentView {
        EmptyContentView(configuration: self, message: message)
    }

    func updated(for state: any UIConfigurationState) -> EmptyContentConfiguration {
        self
    }
}

final class EmptyContentView: UIView, UIContentView {
    var configuration: UIContentConfiguration {
        didSet { apply(configuration: configuration) }
    }
    let message: String

    // MARK: - Component

    private lazy var messageLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.setTypography(text: message, style: .subtitle2)
        l.numberOfLines = 0
        l.textColor = UIColor.gray600
        l.textAlignment = .center
        return l
    }()

    // MARK: Initialize

    init(configuration: UIContentConfiguration, message: String) {
        self.configuration = configuration
        self.message = message
        super.init(frame: .zero)
        setup()
        apply(configuration: configuration)
    }

    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - SetUp

    private func setup() {
        addSubview(messageLabel)
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 96),
            messageLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -96)
        ])
    }

    // MARK: - Apply

    private func apply(configuration: UIContentConfiguration) {
        guard configuration is EmptyContentConfiguration else { return }
    }
}
