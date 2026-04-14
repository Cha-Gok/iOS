import UIKit

struct MainEmptyContentConfiguration: UIContentConfiguration {
    func makeContentView() -> any UIView & UIContentView {
        MainEmptyContentView(configuration: self)
    }

    func updated(for state: any UIConfigurationState) -> MainEmptyContentConfiguration {
        self
    }
}

final class MainEmptyContentView: UIView, UIContentView {
    var configuration: UIContentConfiguration {
        didSet { apply(configuration: configuration) }
    }

    // MARK: - Component

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.setTypography(text: "아직 녹음된 기록이 없습니다", style: .subtitle2)
        l.textColor = UIColor.gray600
        l.textAlignment = .center
        return l
    }()

    // MARK: Initialize

    init(configuration: UIContentConfiguration) {
        self.configuration = configuration
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
        guard configuration is MainEmptyContentConfiguration else { return }
    }
}
