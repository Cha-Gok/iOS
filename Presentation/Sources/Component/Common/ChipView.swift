import UIKit

final class ChipView: UIView {
    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = UIColor.gray775
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.gray775
        label.setTypography(style: .label)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Constant.chipContentSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    init(icon: UIImage?, text: String) {
        super.init(frame: .zero)
        setupUI()
        iconView.image = icon
        label.text = text
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    private func setupUI() {
        backgroundColor = UIColor.point150
        layer.borderColor = UIColor.point600.cgColor
        layer.borderWidth = Constant.borderWidth
        clipsToBounds = true

        addSubview(stackView)
        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(label)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Constant.chipVerticalPadding),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constant.chipHorizontalPadding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constant.chipHorizontalPadding),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constant.chipVerticalPadding),
            iconView.widthAnchor.constraint(equalToConstant: Constant.chipIconSize),
            iconView.heightAnchor.constraint(equalToConstant: Constant.chipIconSize),
            heightAnchor.constraint(greaterThanOrEqualToConstant: Constant.chipMinimumHeight)
        ])
    }
}

#Preview {
    ChipView(icon: UIImage(systemName: "arrow.clockwise"), text: "재생성")
}
