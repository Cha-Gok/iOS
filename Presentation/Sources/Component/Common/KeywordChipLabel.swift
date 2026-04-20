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

    override public func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    override public func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetBounds = bounds.inset(by: insets)
        let textRect = super.textRect(forBounds: insetBounds, limitedToNumberOfLines: numberOfLines)
        let invertedInsets = UIEdgeInsets(
            top: -insets.top, left: -insets.left,
            bottom: -insets.bottom, right: -insets.right
        )

        return textRect.inset(by: invertedInsets)
    }

    override public func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
}

#Preview {
    KeywordChipLabel(text: "키워드 칩")
}
