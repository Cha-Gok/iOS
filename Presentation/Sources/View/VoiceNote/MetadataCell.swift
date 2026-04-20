import UIKit

// MARK: - MetadataContentConfiguration

struct MetadataContentConfiguration: UIContentConfiguration {
    var folderName: String = ""
    var date: String = ""
    var duration: String = ""

    func makeContentView() -> UIView & UIContentView {
        MetadataContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> MetadataContentConfiguration {
        self
    }
}

// MARK: - MetadataContentView

final class MetadataContentView: UIView, UIContentView {
    var configuration: UIContentConfiguration {
        didSet { apply(configuration: configuration) }
    }

    // MARK: - UI Components

    private let folderRow: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let folderIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "folder"))
        imageView.tintColor = .metadataLabel
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let folderLabel: UILabel = {
        let label = UILabel()
        label.textColor = .metadataLabel
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = .metadataLabel
        return label
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .metadataLabel
        return label
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
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
        folderRow.addArrangedSubview(folderIcon)
        folderRow.addArrangedSubview(folderLabel)

        stackView.addArrangedSubview(folderRow)
        stackView.addArrangedSubview(dateLabel)
        stackView.addArrangedSubview(durationLabel)
        stackView.setCustomSpacing(15, after: folderRow)

        addSubview(stackView)
        NSLayoutConstraint.activate([
            folderIcon.widthAnchor.constraint(equalToConstant: 20),
            folderIcon.heightAnchor.constraint(equalToConstant: 20),

            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Apply

    private func apply(configuration: UIContentConfiguration) {
        guard let config = configuration as? MetadataContentConfiguration else { return }
        folderLabel.setTypography(text: config.folderName, style: .body1)
        dateLabel.setTypography(text: config.date, style: .body1)
        durationLabel.setTypography(text: config.duration, style: .body1)
    }
}
