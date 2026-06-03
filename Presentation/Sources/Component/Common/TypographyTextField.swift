import UIKit

/// Typography를 생성자로 받아 텍스트 변경 시에도 타이포그래피 속성을 유지하는 UITextField 서브클래스.
/// 프로그래매틱 할당은 `attributedText`로, 편집 중 입력은 `defaultTextAttributes`로 속성을 유지합니다.
public class TypographyTextField: UITextField {
    public var typography: Typography {
        didSet { applyTypography() }
    }

    public var typographyAlignment: NSTextAlignment {
        didSet {
            textAlignment = typographyAlignment
            applyTypography()
        }
    }

    override public var text: String? {
        didSet { applyTypography() }
    }

    override public var textColor: UIColor? {
        didSet { applyTypography() }
    }

    public init(typography: Typography, alignment: NSTextAlignment = .left) {
        self.typography = typography
        typographyAlignment = alignment
        super.init(frame: .zero)
        textAlignment = alignment
        contentVerticalAlignment = .center
        applyTypography()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override public func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds
    }

    override public func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds
    }

    override public func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        bounds
    }

    private func applyTypography() {
        var attributes = typography.textAttributes

        if let paragraphStyle = (attributes[.paragraphStyle] as? NSParagraphStyle)?
            .mutableCopy() as? NSMutableParagraphStyle
        {
            paragraphStyle.alignment = typographyAlignment
            attributes[.paragraphStyle] = paragraphStyle
        }

        // UILabel은 baselineOffset을 이중 적용하지만 UITextField는 단일 적용하므로,
        // 동일한 속성을 주면 Label 대비 텍스트가 아래로 밀린다.
        // 2배로 보정하여 Label과 동일한 수직 위치를 맞춘다.
        if let offset = attributes[.baselineOffset] as? CGFloat {
            attributes[.baselineOffset] = offset * 2
        }

        if let textColor {
            attributes[.foregroundColor] = textColor
        }

        super.attributedText = NSAttributedString(string: text ?? "", attributes: attributes)
        defaultTextAttributes = attributes
    }
}

#Preview {
    let viewController = UIViewController()
    viewController.view.backgroundColor = .systemBackground

    let displayField = TypographyTextField(typography: .title1)
    displayField.text = "Title1 — 표시 전용"
    displayField.isEnabled = false
    displayField.textColor = .gray950

    let editingField = TypographyTextField(typography: .body1)
    editingField.text = "Body1 — 편집 가능"
    editingField.textColor = .gray950

    let stack = UIStackView(arrangedSubviews: [displayField, editingField])
    stack.axis = .vertical
    stack.spacing = 16
    stack.translatesAutoresizingMaskIntoConstraints = false
    viewController.view.addSubview(stack)

    NSLayoutConstraint.activate([
        stack.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 20),
        stack.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -20),
        stack.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
    ])

    return viewController
}
