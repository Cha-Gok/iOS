import UIKit

// MARK: - KeywordsSkeletonContentConfiguration

struct KeywordsSkeletonContentConfiguration: UIContentConfiguration {
    var beginOffset: CFTimeInterval = 0

    func makeContentView() -> UIView & UIContentView {
        KeywordsSkeletonContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> KeywordsSkeletonContentConfiguration {
        self
    }
}

// MARK: - KeywordsSkeletonContentView

final class KeywordsSkeletonContentView: UIView, UIContentView {
    var configuration: UIContentConfiguration {
        didSet { apply(configuration: configuration) }
    }

    private let skeletonLine = SkeletonLineView()

    // MARK: - Init

    init(configuration: UIContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        backgroundColor = UIColor.gray100
        setupUI()
        apply(configuration: configuration)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: KeywordChipLabel.standardHeight)
    }

    // MARK: - Setup

    private func setupUI() {
        skeletonLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(skeletonLine)

        NSLayoutConstraint.activate([
            skeletonLine.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: Constant.keywordChipHorizontalPadding
            ),
            skeletonLine.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -Constant.keywordChipHorizontalPadding
            ),
            skeletonLine.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    // MARK: - Apply

    private func apply(configuration: UIContentConfiguration) {
        guard let config = configuration as? KeywordsSkeletonContentConfiguration else { return }
        skeletonLine.startAnimating(beginOffset: config.beginOffset)
    }
}

// MARK: - Preview

#Preview {
    let preview: UIView = {
        let configs = [
            KeywordsSkeletonContentConfiguration(beginOffset: 0.0),
            KeywordsSkeletonContentConfiguration(beginOffset: 0.2),
        ]

        let stack = UIStackView(arrangedSubviews: configs.map { $0.makeContentView() })
        stack.axis = .vertical
        stack.spacing = Constant.keywordChipLineSpacing
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.backgroundColor = .systemPink
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        return container
    }()

    preview
}
