import UIKit

public final class KeywordChipLabel: TypographyLabel {
    private let insets = UIEdgeInsets(
        top: Constant.keywordChipVerticalPadding,
        left: Constant.keywordChipHorizontalPadding,
        bottom: Constant.keywordChipVerticalPadding,
        right: Constant.keywordChipHorizontalPadding
    )

    private var baseText: String = ""

    public init(text: String) {
        super.init(typography: .label)
        textColor = UIColor.gray750
        backgroundColor = UIColor.gray100
        clipsToBounds = true
        baseText = text
        self.text = text
    }

    /// 텍스트 내 `query`에 일치하는 모든 범위에 형광펜 스타일의 배경 하이라이트를 적용합니다.
    /// `query`가 비어 있으면 기본 타이포그래피로 복원됩니다.
    /// `focusedRange`가 지정되면 해당 범위는 `focusedHighlightBackgroundColor`로 덮어씌웁니다.
    public func applyHighlight(
        query: String,
        highlightBackgroundColor: UIColor,
        focusedRange: NSRange? = nil,
        focusedHighlightBackgroundColor: UIColor? = nil
    ) {
        guard !query.isEmpty else {
            text = baseText
            return
        }
        attributedText = baseText.highlighted(
            query: query,
            baseAttributes: typography.textAttributes,
            highlightBackgroundColor: highlightBackgroundColor,
            focusedRange: focusedRange,
            focusedHighlightBackgroundColor: focusedHighlightBackgroundColor
        )
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
