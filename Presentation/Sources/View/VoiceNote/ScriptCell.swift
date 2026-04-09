import UIKit

// MARK: - ScriptContentConfiguration

struct ScriptContentConfiguration: UIContentConfiguration {
    var timestamp: String = ""
    var paragraphs: [String] = []
    /// 현재 재생 중인 문단 인덱스. nil이면 하이라이팅 없음
    var highlightedParagraphIndex: Int?

    func makeContentView() -> UIView & UIContentView {
        ScriptContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> ScriptContentConfiguration {
        self
    }
}

// MARK: - ScriptContentView

final class ScriptContentView: UIView, UIContentView {
    var configuration: UIContentConfiguration {
        didSet { apply(configuration: configuration) }
    }

    // MARK: - UI Components

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.gray600
        return label
    }()

    private let paragraphsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }()

    private let containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
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
        containerStack.addArrangedSubview(timeLabel)
        containerStack.addArrangedSubview(paragraphsStack)
        addSubview(containerStack)

        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: topAnchor),
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Apply

    private func apply(configuration: UIContentConfiguration) {
        guard let config = configuration as? ScriptContentConfiguration else { return }
        timeLabel.setTypography(text: config.timestamp, style: .caption)

        paragraphsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, para) in config.paragraphs.enumerated() {
            let label = UILabel()
            let isHighlighted = config.highlightedParagraphIndex == index
            label.textColor = isHighlighted ? .white : UIColor.gray600
            label.setTypography(text: para, style: .body1)
            label.numberOfLines = 0
            paragraphsStack.addArrangedSubview(label)
        }
    }
}
