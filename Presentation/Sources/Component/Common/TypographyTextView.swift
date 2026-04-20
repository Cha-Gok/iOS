import UIKit

/// Typography를 생성자로 받아 텍스트 변경 시에도 타이포그래피 속성을 유지하는 UITextView 서브클래스.
/// 프로그래매틱 할당은 `attributedText`로, 편집 중 입력은 `typingAttributes`로 속성을 유지합니다.
public class TypographyTextView: UITextView {
    public var typography: Typography {
        didSet { applyTypography() }
    }

    public var typographyAlignment: NSTextAlignment {
        didSet { applyTypography() }
    }

    public override var text: String! {
        didSet { applyTypography() }
    }

    public init(typography: Typography, alignment: NSTextAlignment = .left) {
        self.typography = typography
        self.typographyAlignment = alignment
        super.init(frame: .zero, textContainer: nil)
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
        typingAttributes = attributes
    }
}

#Preview {
    let viewController = UIViewController()
    viewController.view.backgroundColor = .systemBackground

    let displayTextView = TypographyTextView(typography: .body1)
    displayTextView.text = "Body1 — 표시 전용 텍스트입니다.\n줄바꿈과 행간을 확인합니다."
    displayTextView.isEditable = false
    displayTextView.isScrollEnabled = false
    displayTextView.backgroundColor = .gray100

    let editingTextView = TypographyTextView(typography: .body2)
    editingTextView.text = "Body2 — 편집 모드에서 typingAttributes로 스타일이 유지됩니다."
    editingTextView.isScrollEnabled = false
    editingTextView.backgroundColor = .gray50

    let stack = UIStackView(arrangedSubviews: [displayTextView, editingTextView])
    stack.axis = .vertical
    stack.spacing = 16
    stack.translatesAutoresizingMaskIntoConstraints = false
    viewController.view.addSubview(stack)

    NSLayoutConstraint.activate([
        stack.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 20),
        stack.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -20),
        stack.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor),
    ])

    return viewController
}
