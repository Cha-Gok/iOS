import UIKit

// MARK: - Content Configuration

struct MainCategoryContentConfiguration: UIContentConfiguration {
    var imageName: String = ""
    var title: String = ""
    var totalCount: Int = 0
    var isSelected: Bool = false

    func makeContentView() -> UIView & UIContentView {
        MainCategoryContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> MainCategoryContentConfiguration {
        guard let state = state as? UICellConfigurationState else { return self }
        var updatedConfig = self
        updatedConfig.isSelected = state.isSelected
        return updatedConfig
    }
}

// MARK: - Content View

final class MainCategoryContentView: UIView, UIContentView {
    var configuration: UIContentConfiguration {
        didSet { apply(configuration: configuration) }
    }

    /// Components
    private let container: UIView = {
        let c = UIView()
        c.translatesAutoresizingMaskIntoConstraints = false
        c.layer.cornerRadius = 20
        c.layer.borderWidth = 1.0
        c.layer.borderColor = UIColor.gray600.cgColor
        return c
    }()

    private let imageView: UIImageView = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        img.contentMode = .scaleAspectFit
        img.tintColor = UIColor.gray600
        return img
    }()

    private let titleLabel: UILabel = {
        let t = UILabel()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.textColor = UIColor.gray600
        return t
    }()

    private let countView: UILabel = {
        let c = UILabel()
        c.translatesAutoresizingMaskIntoConstraints = false
        c.textColor = UIColor.gray750
        return c
    }()

    /// Init
    init(configuration: MainCategoryContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        setup()
        apply(configuration: configuration)
    }

    required init?(coder: NSCoder) {
        nil
    }

    /// Setup & Constraints
    private func setup() {
        addSubview(container)
        container.addSubview(imageView)
        container.addSubview(titleLabel)
        container.addSubview(countView)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16)
        ])

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])

        NSLayoutConstraint.activate([
            countView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            countView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            countView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            countView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
    }

    func setSelectedState(_ isSelected: Bool, totalCount: Int) {
        UIView.animate(withDuration: 0.2) {
            self.container.layer.borderColor = isSelected ? UIColor.point900.cgColor : UIColor.gray600.cgColor
            self.container.layer.borderWidth = isSelected ? 2.0 : 1.0
            self.countView.setTypography(text: String(totalCount), style: isSelected ? .title3 : .label)
            self.titleLabel.textColor = isSelected ? UIColor.gray950 : UIColor.gray600
            self.imageView.tintColor = isSelected ? UIColor.gray950 : UIColor.gray600
        }
    }

    /// Apply
    private func apply(configuration: UIContentConfiguration) {
        guard let configuration = configuration as? MainCategoryContentConfiguration else { return }
        imageView.image = UIImage(systemName: configuration.imageName)
        titleLabel.setTypography(text: configuration.title, style: .subtitle2)
        countView.setTypography(text: String(configuration.totalCount), style: .label)
        setSelectedState(configuration.isSelected, totalCount: configuration.totalCount)
    }
}
