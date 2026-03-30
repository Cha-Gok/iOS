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

    // TODO: 행간
    public var lineHeightMultiple: CGFloat {
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
}

public extension UILabel {
    /// Typography를 적용합니다.
    /// - Parameters:
    ///   - text: UILabel의 텍스트 입니다.
    ///   - typography: 글씨체, 행간 , 자간 복합적인 열겨형 데이터
    func setTypography(text: String? = nil, style typography: Typography) {
        let textToUse = text ?? self.text ?? ""

        let paragraphStyle = NSMutableParagraphStyle()
        // lineHeightMultiple을 설정하면 남는 여백이 주로 위쪽에 추가되어 텍스트가 아래로 쏠려 보입니다.
        let fontLineHeight = typography.font.lineHeight
        let targetLineHeight = fontLineHeight * typography.lineHeightMultiple

        paragraphStyle.minimumLineHeight = targetLineHeight
        paragraphStyle.maximumLineHeight = targetLineHeight

        // 여백(targetLineHeight - fontLineHeight)의 절반만큼 위로 끌어올리면 정확히 중앙에 배치됩니다.
        let baselineOffset = (targetLineHeight - fontLineHeight) / 2

        let attributes: [NSAttributedString.Key: Any] = [
            .font: typography.font,
            .paragraphStyle: paragraphStyle,
            .kern: typography.letterSpacing,
            .baselineOffset: baselineOffset // 계산된 값 적용
        ]
        attributedText = NSAttributedString(string: textToUse, attributes: attributes)
    }
}
