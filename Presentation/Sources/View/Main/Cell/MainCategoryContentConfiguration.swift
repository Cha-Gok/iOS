import UIKit

// MARK: - Content Configuration

struct MainCategoryContentConfiguration: UIContentConfiguration {
    var imageName: String = ""
    var title: String = ""
    var totalCount: Int = 0
    var isSelected: Bool = false
    var didScroll: Bool = false

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
    private let container: UIStackView = {
        let c = UIStackView()
        c.translatesAutoresizingMaskIntoConstraints = false
        c.axis = .vertical
        c.alignment = .fill
        c.spacing = 0
        c.isLayoutMarginsRelativeArrangement = true
        c.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        c.layer.cornerRadius = 20
        c.layer.borderWidth = 1.0
        c.layer.borderColor = UIColor.gray600.cgColor
        return c
    }()

    private let imageRow: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 0
        return stackView
    }()

    private let imageSpacer = UIView()

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
        t.numberOfLines = 1
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
        container.addArrangedSubview(imageRow)
        imageRow.addArrangedSubview(imageView)
        imageRow.addArrangedSubview(imageSpacer)
        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(countView)
        container.setCustomSpacing(6, after: imageRow)
        container.setCustomSpacing(16, after: titleLabel)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalToConstant: 20)
        ])

        imageRow.setContentHuggingPriority(.required, for: .horizontal)
        imageRow.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
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

    func setDidScrollState(_ didScroll: Bool) {
        container.axis = didScroll ? .horizontal : .vertical
        container.alignment = didScroll ? .center : .fill
        container.spacing = didScroll ? 6 : 0
        container.layoutMargins = didScroll
            ? UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
            : UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        container.layer.cornerRadius = didScroll ? 18 : 20
        imageSpacer.isHidden = didScroll
        countView.isHidden = didScroll
    }

    /// Apply
    private func apply(configuration: UIContentConfiguration) {
        guard let configuration = configuration as? MainCategoryContentConfiguration else { return }
        imageView.image = UIImage(systemName: configuration.imageName)
        titleLabel.setTypography(text: configuration.title, style: .subtitle2)
        countView.setTypography(text: String(configuration.totalCount), style: .label)
        setSelectedState(configuration.isSelected, totalCount: configuration.totalCount)
        setDidScrollState(configuration.didScroll)
    }
}
