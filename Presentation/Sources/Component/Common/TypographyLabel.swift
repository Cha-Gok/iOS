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

    public override var text: String? {
        didSet { applyTypography() }
    }

    public init(typography: Typography, alignment: NSTextAlignment = .left) {
        self.typography = typography
        self.typographyAlignment = alignment
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
            attributes[.paragraphStyle] = paragraphStyle
        }

        super.attributedText = NSAttributedString(string: text ?? "", attributes: attributes)
    }
}
