import UIKit

final class ChagokSearchBar: UIView {
    // MARK: - Component

    private let searchContainer: UIVisualEffectView = {
        let effect = UIGlassEffect(style: .clear)
        effect.tintColor = .point100.withAlphaComponent(0.2)
        let view = UIVisualEffectView()
        view.cornerConfiguration = .corners(
            radius: .fixed(Constant.cornerRadius)
        )
        UIView.animate {
            effect.isInteractive = true
            view.effect = effect
        }
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.gray600.cgColor
        return view
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView(image: .search)
        imageView.tintColor = .gray850
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let textField: TypographyTextField = {
        let field = TypographyTextField(typography: .body1)
        field.textColor = .white
        field.tintColor = .white
        field.returnKeyType = .search
        field.clearButtonMode = .never
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.spellCheckingType = .no
        var placeholderAttrs = Typography.body1.textAttributes
        placeholderAttrs[.foregroundColor] = UIColor.gray950
        field.attributedPlaceholder = NSAttributedString(string: "검색", attributes: placeholderAttrs)
        return field
    }()

    let closeButton: UIButton = {
        var config = UIButton.Configuration.prominentClearGlass()
        config.image = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12))
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .point100.withAlphaComponent(0.2)
        config.contentInsets = .zero
        return UIButton(configuration: config)
    }()

    // MARK: - Initialize

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.layoutFittingExpandedSize.width, height: 46)
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(searchContainer)
        addSubview(closeButton)
        searchContainer.contentView.addSubview(iconView)
        searchContainer.contentView.addSubview(textField)

        for item in [searchContainer, closeButton, iconView, textField] {
            item.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 46),

            searchContainer.topAnchor.constraint(equalTo: topAnchor),
            searchContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            searchContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            searchContainer.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -12),

            closeButton.topAnchor.constraint(equalTo: topAnchor),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 46),
            closeButton.heightAnchor.constraint(equalToConstant: 46),

            iconView.leadingAnchor.constraint(equalTo: searchContainer.contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: searchContainer.contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            textField.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: searchContainer.contentView.trailingAnchor, constant: -16),
            textField.topAnchor.constraint(equalTo: searchContainer.contentView.topAnchor),
            textField.bottomAnchor.constraint(equalTo: searchContainer.contentView.bottomAnchor)
        ])
    }
}

#Preview {
    let vc = UIViewController()
    vc.view.backgroundColor = .gray50
    let bar = ChagokSearchBar()
    bar.translatesAutoresizingMaskIntoConstraints = false
    vc.view.addSubview(bar)
    NSLayoutConstraint.activate([
        bar.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 16),
        bar.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -16),
        bar.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor),
        bar.heightAnchor.constraint(equalToConstant: 46)
    ])
    return vc
}
