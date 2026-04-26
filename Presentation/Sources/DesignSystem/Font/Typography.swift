import SwiftUI
import UIKit

public enum Typography {
    case header1
    case header2
    case title1
    case title2
    case title3
    case subtitle1
    case subtitle2
    case body1
    case body2
    case body3
    case label
    case caption

    public var font: UIFont {
        switch self {
        case .header1: return PretendardFont.medium(size: 28)
        case .header2: return PretendardFont.bold(size: 24)
        case .title1: return PretendardFont.bold(size: 20)
        case .title2: return PretendardFont.bold(size: 18)
        case .title3: return PretendardFont.bold(size: 16)
        case .subtitle1: return PretendardFont.medium(size: 18)
        case .subtitle2: return PretendardFont.medium(size: 16)
        case .body1: return PretendardFont.regular(size: 16)
        case .body2: return PretendardFont.regular(size: 16)
        case .body3: return PretendardFont.regular(size: 15)
        case .label: return PretendardFont.regular(size: 15)
        case .caption: return PretendardFont.regular(size: 14)
        }
    }

    /// Figma 스펙의 line-height 비율(폰트 크기 대비). 130% → 1.3, 150% → 1.5.
    public var lineHeightRatio: CGFloat {
        switch self {
        case .header1, .header2, .title1, .title2, .title3, .subtitle2, .body2, .label, .caption:
            return 1.3
        case .subtitle1, .body1, .body3:
            return 1.5
        }
    }

    // TODO: 자간
    public var letterSpacing: CGFloat {
        let size = font.pointSize
        switch self {
        case .header1, .subtitle1:
            return 0
        case .header2, .title1, .title2, .title3, .caption:
            return size * -0.02
        case .subtitle2, .body1, .body2, .body3, .label:
            return size * -0.03
        }
    }

    var textAttributes: [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        let targetLineHeight = font.pointSize * lineHeightRatio

        paragraphStyle.minimumLineHeight = targetLineHeight
        paragraphStyle.maximumLineHeight = targetLineHeight

        let baselineOffset = (targetLineHeight - font.lineHeight) / 2

        return [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .kern: letterSpacing,
            .baselineOffset: baselineOffset
        ]
    }
}

public extension UILabel {
    /// Typography를 적용합니다.
    /// - Parameters:
    ///   - text: UILabel의 텍스트 입니다.
    ///   - typography: 글씨체, 행간 , 자간 복합적인 열겨형 데이터
    ///   - textAlignment: 텍스트 정렬 설정 (기본값: .left)
    func setTypography(text: String? = nil, style typography: Typography, textAlignment: NSTextAlignment = .left) {
        let textToUse = text ?? self.text ?? ""
        var attributes = typography.textAttributes

        if let paragraphStyle = (attributes[.paragraphStyle] as? NSParagraphStyle)?
            .mutableCopy() as? NSMutableParagraphStyle
        {
            paragraphStyle.alignment = textAlignment
            attributes[.paragraphStyle] = paragraphStyle
        }

        attributedText = NSAttributedString(string: textToUse, attributes: attributes)
    }
}

public extension View {
    /// SwiftUI View에 Typography를 적용합니다.
    func typography(_ style: Typography) -> some View {
        let targetLineHeight = style.font.pointSize * style.lineHeightRatio
        let spacing = targetLineHeight - style.font.lineHeight

        return font(Font(style.font))
            .tracking(style.letterSpacing)
            .lineSpacing(max(0, spacing))
    }
}
