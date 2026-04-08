import UIKit

final class MainCategoryViewCell: UICollectionViewCell {
    static let reuseIdentifier: String = "MainCategoryViewCell"

    private(set) var imageName: String = ""
    private(set) var title: String = ""
    private(set) var totalCount: Int = 0

    // MARK: - Component

    private let container: UIView = {
        let c = UIView()
        c.translatesAutoresizingMaskIntoConstraints = false
        c.layer.cornerRadius = 20
        c.layer.borderWidth = 1.0
        c.layer.borderColor = UIColor.gray600.cgColor
        return c
    }()

    private lazy var imageView: UIImageView = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        img.contentMode = .scaleAspectFit
        img.tintColor = UIColor.gray600
        img.image = UIImage(systemName: imageName)
        return img
    }()

    private lazy var titleLabel: UILabel = {
        let t = UILabel()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.setTypography(text: title, style: .subtitle2)
        t.textColor = UIColor.gray600
        return t
    }()

    private lazy var countView: UILabel = {
        let c = UILabel()
        c.translatesAutoresizingMaskIntoConstraints = false
        c.setTypography(text: String(totalCount), style: .label)
        c.textColor = UIColor.gray750
        return c
    }()

    // MARK: - Initialize

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure

    func configure(imageName: String, title: String, totalCount: Int) {
        self.imageName = imageName
        self.title = title
        self.totalCount = totalCount
        imageView.image = UIImage(systemName: imageName)
        titleLabel.setTypography(text: title, style: .subtitle2)
        countView.setTypography(text: String(totalCount), style: .title3)
    }

    // MARK: - setup

    private func setup() {
        container.addSubview(imageView)
        container.addSubview(titleLabel)
        container.addSubview(countView)
        contentView.addSubview(container)
        // 제약 조건
        containerConstraint()
        imageViewConstraint()
        titleLabelConstraint()
        countViewConstraint()
    }

    // MARK: - Constraint

    private func containerConstraint() {
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func imageViewConstraint() {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16)
        ])
    }

    private func titleLabelConstraint() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])
    }

    private func countViewConstraint() {
        NSLayoutConstraint.activate([
            countView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            countView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            countView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            countView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
    }

    // MARK: - Selection Animation

    override var isSelected: Bool {
        didSet { updateVisualState() }
    }

    private func updateVisualState() {
        let isActive = isSelected
        UIView.animate(withDuration: 0.1) {
            self.container.layer.borderColor = isActive ? UIColor.point900.cgColor : UIColor.gray600.cgColor
            self.container.layer.borderWidth = isActive ? 2.0 : 1.0
            self.countView.setTypography(
                text: String(self.totalCount),
                style: isActive ? .title3 : .label
            )
            self.titleLabel.textColor = isActive ? UIColor.gray950 : UIColor.gray600
            self.imageView.tintColor = isActive ? UIColor.gray950 : UIColor.gray600
        }
    }
}
