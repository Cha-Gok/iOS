import Foundation

// MARK: - General UI Constants

public enum Constant {
    /// 차곡 기본 Corner Radius 상수 값
    static let cornerRadius: CGFloat = 20

    /// 차곡 공통 Capsule Corner Radius 상수 값
    static let capsuleCornerRadius: CGFloat = 99

    /// View Background Opacity alpha
    static let backgroundOpacity: CGFloat = 0.2

    /// GlassButton Border Width 상수 값 (앱 전반 테두리로 사용 시)
    static let borderWidth: CGFloat = 1.0

    /// Animation Duration 값
    static let animationDuration: CGFloat = 0.3
}

// MARK: - GlassButton Constants

public extension Constant {
    /// GlassButton Shadow 상수 값
    static let shadowOpacity: Float = 0.16

    /// GlassButton Shadow Offset ( width, height )
    static let shadowOffsetWidth: CGFloat = 2
    static let shadowOffsetHeight: CGFloat = 2
}

// MARK: - AlertView Constants

public extension Constant {
    /// AlertView Spacing 상수 값
    static let alertSpacing: CGFloat = 8

    /// AlertView( TopContent ) Top And Bottom 제약조건 상수 값
    static let alertTopAndBottomValueForTopContent: CGFloat = 32

    /// AlertView( TopContent ) Leading And Trailing 제약조건 상수 값
    static let alertLeftAndRightValueForTopContent: CGFloat = 40

    /// AlertView( BottomContent ) Top And Bottom 제약조건 상수 값
    static let alertTopAndBottomValueForBottomContent: CGFloat = 20

    /// AlertView( BottomContent ) Leading And Trailing 제약조건 상수 값
    static let alertLeftAndRightValueForBottomContent: CGFloat = 20

    /// AlertView TopContent와 BottomContent의 Spacing 상수 값
    static let alertTopAndBottomContentSpacing: CGFloat = 24

    /// AlertView BottomContent Height 상수 값
    static let alertBottomContentHeight: CGFloat = 46

    /// AlertView Width multiplier 비율 값
    static let alertMultiplierWidth: CGFloat = 0.8

    /// AlertView Height multiplier 비율 값
    static let alertMultiplierHeight: CGFloat = 0.3
}

// MARK: - Pagenation Constants

public extension Constant {
    /// Pagenation 이동 Count 상수 값
    static let pagenationMoveCount: Int = 1

    /// Pagenation 높이 상수 값
    static let pagenationHeight: CGFloat = 2

    /// Pagenation Spacing 값
    static let pagenationSpacing: CGFloat = 4

    /// Pagenation Total Count 값
    static let pagenationTotalValue: Int = 4
}
