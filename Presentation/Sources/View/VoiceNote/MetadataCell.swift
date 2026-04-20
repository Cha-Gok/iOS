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
        stack.spacing = Constant.metadataCellIconSpacing
        return stack
    }()

    private let folderIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "folder"))
        imageView.tintColor = .metadataLabel
        return imageView
    }()

    private let folderLabel: UILabel = {
        let label = UILabel()
        label.setTypography(style: .body1)
        label.textColor = .metadataLabel
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.setTypography(style: .body1)
        label.textColor = .metadataLabel
        return label
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.setTypography(style: .body1)
        label.textColor = .metadataLabel
        return label
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Constant.metadataCellLineSpacing
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
        stackView.setCustomSpacing(Constant.metadataCellSectionSpacing, after: folderRow)

        addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        folderIcon.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            folderIcon.widthAnchor.constraint(equalToConstant: Constant.metadataCellIconSize),
            folderIcon.heightAnchor.constraint(equalToConstant: Constant.metadataCellIconSize),

            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Apply

    private func apply(configuration: UIContentConfiguration) {
        guard let config = configuration as? MetadataContentConfiguration else { return }
        folderLabel.text = config.folderName
        dateLabel.text = config.date
        durationLabel.text = config.duration
    }
}

// MARK: - Preview

#Preview {
    let config = MetadataContentConfiguration(
        folderName: "회의 노트",
        date: "2026년 4월 20일 오후 2:30",
        duration: "재생시간 12:34"
    )
    let cell = MetadataContentView(configuration: config)
    cell.translatesAutoresizingMaskIntoConstraints = false

    let container = UIView()
    container.backgroundColor = .gray100
    container.addSubview(cell)

    NSLayoutConstraint.activate([
        cell.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
        cell.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
        cell.centerYAnchor.constraint(equalTo: container.centerYAnchor)
    ])

    return container
}
