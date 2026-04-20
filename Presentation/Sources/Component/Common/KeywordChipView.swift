import UIKit

public final class KeywordChipView: UIView {
    private let label: TypographyLabel = {
        let label = TypographyLabel(typography: .label)
        label.textColor = UIColor.gray950
        return label
    }()

    public init(text: String) {
        super.init(frame: .zero)
        setupUI()
        label.text = text
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    private func setupUI() {
        backgroundColor = UIColor.gray100
        clipsToBounds = true

        addSubview(label)

        translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constant.keywordChipHorizontalPadding),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constant.keywordChipHorizontalPadding),
            label.topAnchor.constraint(equalTo: topAnchor, constant: Constant.keywordChipVerticalPadding),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constant.keywordChipVerticalPadding),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 32)
        ])
    }
}

#Preview {
    KeywordChipView(text: "키워드 칩")
}
