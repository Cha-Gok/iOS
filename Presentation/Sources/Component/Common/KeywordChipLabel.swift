import UIKit

public final class KeywordChipLabel: TypographyLabel {
    private let insets = UIEdgeInsets(
        top: Constant.keywordChipVerticalPadding,
        left: Constant.keywordChipHorizontalPadding,
        bottom: Constant.keywordChipVerticalPadding,
        right: Constant.keywordChipHorizontalPadding
    )

    public init(text: String) {
        super.init(typography: .label)
        textColor = UIColor.gray950
        backgroundColor = UIColor.gray100
        clipsToBounds = true
        self.text = text
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    public override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    public override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
}

#Preview {
    KeywordChipLabel(text: "키워드 칩")
}
