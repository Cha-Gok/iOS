import UIKit

public struct FolderCellContentConfiguration: UIContentConfiguration {
    let title: String
    let number: Int
    var isSelected: Bool = false

    public func makeContentView() -> any UIView & UIContentView {
        FolderCellContentView(configuration: self)
    }

    public func updated(for state: any UIConfigurationState) -> FolderCellContentConfiguration {
        var updated = self
        if let cellState = state as? UICellConfigurationState {
            updated.isSelected = cellState.isSelected
        }
        return updated
    }
}

final class FolderCellContentView: UIView, UIContentView {
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = .folder
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.setTypography(style: .body2)
        label.textColor = .gray800
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.setTypography(style: .body2)
        label.textColor = .gray750
        return label
    }()

    private let backgroundView: UIVisualEffectView = {
        let glassEffect = UIGlassEffect()
        glassEffect.tintColor = UIColor(red: 0x13 / 255, green: 0x00 / 255, blue: 0x3f / 255, alpha: 0x33 / 255)
        let view = UIVisualEffectView(effect: glassEffect)
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        return view
    }()

    var configuration: any UIContentConfiguration {
        didSet { apply(configuration: configuration) }
    }

    init(configuration: any UIContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        setupUI()
        apply(configuration: configuration)
    }

    required init?(coder: NSCoder) {
        nil
    }

    func setupUI() {
        for view in [backgroundView, iconImageView, titleLabel, countLabel] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),

            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            iconImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: countLabel.leadingAnchor, constant: -8),

            countLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            countLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func apply(configuration: any UIContentConfiguration) {
        guard let configuration = configuration as? FolderCellContentConfiguration else { return }
        titleLabel.text = configuration.title
        countLabel.text = configuration.number.formatted()
        backgroundView.layer.borderWidth = configuration.isSelected ? 1 : 0
        backgroundView.layer.borderColor = configuration.isSelected
            ? UIColor(red: 0xd9 / 255, green: 0xb5 / 255, blue: 0xff / 255, alpha: 1).cgColor
            : UIColor.clear.cgColor
    }
}

#Preview {
    let normalConfig = FolderCellContentConfiguration(title: "새 폴더", number: 0)
    let selectedConfig = FolderCellContentConfiguration(title: "선택된 폴더", number: 3, isSelected: true)

    let normalCell = FolderCellContentView(configuration: normalConfig)
    let selectedCell = FolderCellContentView(configuration: selectedConfig)

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false
    [normalCell, selectedCell].forEach { stack.addArrangedSubview($0) }

    let container = UIView()
    container.backgroundColor = .gray100
    container.addSubview(stack)

    NSLayoutConstraint.activate([
        stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
        stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
        stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
    ])

    return container
}
