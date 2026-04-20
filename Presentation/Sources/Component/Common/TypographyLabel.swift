import UIKit

/// Typography를 생성자로 받아 텍스트 변경 시에도 타이포그래피 속성을 유지하는 UILabel 서브클래스.
/// UILabel의 `text` 세터가 `attributedText`를 덮어쓰면서 속성이 초기화되는 문제를 해결합니다.
public class TypographyLabel: UILabel {
    public var typography: Typography {
        didSet { applyTypography() }
    }

    public var typographyAlignment: NSTextAlignment {
        didSet { applyTypography() }
    }

    override public var text: String? {
        didSet { applyTypography() }
    }

    override public var lineBreakMode: NSLineBreakMode {
        didSet { applyTypography() }
    }

    public init(typography: Typography, alignment: NSTextAlignment = .left) {
        self.typography = typography
        typographyAlignment = alignment
        super.init(frame: .zero)
        applyTypography()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private func applyTypography() {
        var attributes = typography.textAttributes

        if let paragraphStyle = (attributes[.paragraphStyle] as? NSParagraphStyle)?
            .mutableCopy() as? NSMutableParagraphStyle
        {
            paragraphStyle.alignment = typographyAlignment
            paragraphStyle.lineBreakMode = lineBreakMode
            attributes[.paragraphStyle] = paragraphStyle
        }

        super.attributedText = NSAttributedString(string: text ?? "", attributes: attributes)
    }
}

#Preview {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 8
    stack.alignment = .leading

    let styles: [(Typography, String)] = [
        (.header1, "Header1"), (.header2, "Header2"),
        (.title1, "Title1"), (.title2, "Title2"), (.title3, "Title3"),
        (.subtitle1, "Subtitle1"), (.subtitle2, "Subtitle2"),
        (.body1, "Body1"), (.body2, "Body2"), (.body3, "Body3"),
        (.label, "Label"), (.caption, "Caption")
    ]

    for (style, name) in styles {
        let label = TypographyLabel(typography: style)
        label.text = "\(name) - 타이포그래피 미리보기"
        stack.addArrangedSubview(label)
    }

    return stack
}
