import UIKit

// MARK: - ScriptSkeletonContentConfiguration

struct ScriptSkeletonContentConfiguration: UIContentConfiguration {
    var beginOffset: CFTimeInterval = 0

    func makeContentView() -> UIView & UIContentView {
        ScriptSkeletonContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> ScriptSkeletonContentConfiguration {
        self
    }
}

// MARK: - ScriptSkeletonContentView

final class ScriptSkeletonContentView: UIView, UIContentView {
    var configuration: UIContentConfiguration {
        didSet { apply(configuration: configuration) }
    }

    private let skeletonLine = SkeletonLineView()

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
        skeletonLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(skeletonLine)

        NSLayoutConstraint.activate([
            skeletonLine.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constant.scriptCellSpacing),
            skeletonLine.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constant.scriptCellSpacing),
            skeletonLine.topAnchor.constraint(equalTo: topAnchor),
            skeletonLine.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Apply

    private func apply(configuration: UIContentConfiguration) {
        guard let config = configuration as? ScriptSkeletonContentConfiguration else { return }
        skeletonLine.startAnimating(beginOffset: config.beginOffset)
    }
}
