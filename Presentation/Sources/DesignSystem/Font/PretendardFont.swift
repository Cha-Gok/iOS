import UIKit

public enum PretendardFont {
    public static func bold(size: CGFloat) -> UIFont {
        return PresentationFontFamily.Pretendard.bold.font(size: size)
    }

    public static func medium(size: CGFloat) -> UIFont {
        return PresentationFontFamily.Pretendard.medium.font(size: size)
    }

    public static func regular(size: CGFloat) -> UIFont {
        return PresentationFontFamily.Pretendard.regular.font(size: size)
    }
}
