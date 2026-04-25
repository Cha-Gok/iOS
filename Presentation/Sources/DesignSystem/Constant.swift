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
    static let animationDuration: CGFloat = 0.15

    /// 공용 버튼 높이 상수 값 (46)
    static let commonButtonHeight: CGFloat = 54
}

// MARK: - GlassButton Constants

public extension Constant {
    /// GlassButton Shadow 상수 값
    static let shadowOpacity: Float = 0.16

    /// GlassButton Shadow Offset ( width, height )
    static let shadowOffsetWidth: CGFloat = 2
    static let shadowOffsetHeight: CGFloat = 2

    /// GlassButton Floating Size
    static let floatingButtonSize: CGFloat = 64
}

// MARK: - AlertView Constants

public extension Constant {
    /// AlertView Spacing Top 상수 값
    static let alertTopContentSpacing: CGFloat = 12

    /// AlertView Spacing Botttom 상수 값
    static let alertBottomContentSpacing: CGFloat = 8

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

// MARK: - OnBoarding Constants

public extension Constant {
    /// OnBoarding 카드 뷰 공통 수평 패딩 (20)
    static let onBoardingHorizontalPadding: CGFloat = 20

    /// OnBoarding 버튼 공통 수평 패딩 (16)
    static let onBoardingButtonHorizontalPadding: CGFloat = 16

    /// OnBoarding 컨텐츠 요소 간 간격 (32)
    static let onBoardingContentSpacing: CGFloat = 32

    /// OnBoarding 페이지네이션과 페이징뷰 사이의 상단 여백 (105)
    static let onBoardingPagingViewTopMargin: CGFloat = 105

    /// OnBoarding 페이징뷰와 버튼 사이의 하단 여백 (16)
    static let onBoardingPagingViewBottomMargin: CGFloat = 16

    /// OnBoarding 버튼 간 상하 간격 (8)
    static let onBoardingButtonSpacing: CGFloat = 8

    /// OnBoardingCardView 바디 라벨과 이미지 사이의 특수 간격 (36)
    static let onBoardingCardImageTopSpacing: CGFloat = 36

    /// OnBoarding 라벨 최대 줄 수 (2)
    static let onBoardingLabelNumberOfLines: Int = 2

    /// OnBoarding 페이지네이션 상단 여백 (52)
    static let onBoardingPaginationTopMargin: CGFloat = 52
}

// MARK: - KeywordChipLabel Constants

public extension Constant {
    /// KeywordChipLabel 수평 패딩 (12)
    static let keywordChipHorizontalPadding: CGFloat = 12

    /// KeywordChipLabel 수직 패딩 (8)
    static let keywordChipVerticalPadding: CGFloat = 8

    /// 키워드 칩 가로 간격 (10)
    static let keywordChipInterItemSpacing: CGFloat = 10

    /// 키워드 칩 세로 간격 (10)
    static let keywordChipLineSpacing: CGFloat = 10
}

// MARK: - ChipView Constants

public extension Constant {
    /// ChipView 내부 수평 패딩 (12)
    static let chipHorizontalPadding: CGFloat = 12

    /// ChipView 내부 수직 패딩 (4)
    static let chipVerticalPadding: CGFloat = 4

    /// ChipView 아이콘과 텍스트 사이 간격 (8)
    static let chipContentSpacing: CGFloat = 8

    /// ChipView 아이콘 크기 (16)
    static let chipIconSize: CGFloat = 16

    /// ChipView 최소 높이 (28)
    static let chipMinimumHeight: CGFloat = 28

    /// ChipView 보조 표시 dot 크기 (6)
    static let chipIndicatorSize: CGFloat = 6
}

// MARK: - LanguagePicker Constants

public extension Constant {
    /// LanguagePicker 아이템 간 간격 (8)
    static let languagePickerSpacing: CGFloat = 8

    /// LanguagePicker 라디오 버튼 크기 (16)
    static let languagePickerIndicatorSize: CGFloat = 16

    /// LanguagePicker 선택된 내부 점 크기 (10)
    static let languagePickerInnerIndicatorSize: CGFloat = 10

    /// LanguagePicker 라디오 버튼과 텍스트 사이 간격 (6)
    static let languagePickerTitleSpacing: CGFloat = 6
}

// MARK: - ScriptCell Constants

public extension Constant {
    /// ScriptCell 기본 간격 (8) — 타임스탬프 여백·본문 내부 패딩 공통
    static let scriptCellSpacing: CGFloat = 8

    /// ScriptCell 본문 버블 모서리 반경 (8)
    static let scriptCellCornerRadius: CGFloat = 8
}

// MARK: - MetadataCell Constants

public extension Constant {
    /// MetadataCell 폴더 아이콘과 라벨 사이 간격 (5)
    static let metadataCellIconSpacing: CGFloat = 5

    /// MetadataCell 날짜·재생시간 라벨 사이 간격 (2)
    static let metadataCellLineSpacing: CGFloat = 2

    /// MetadataCell 폴더 행과 날짜 그룹 사이 간격 (11)
    static let metadataCellSectionSpacing: CGFloat = 11

    /// MetadataCell 폴더 아이콘 크기 (20)
    static let metadataCellIconSize: CGFloat = 20
}

// MARK: - KeyPointCell Constants

public extension Constant {
    /// KeyPointCell 번호 뱃지 크기 (24) — 원형 뱃지의 width·height 기준값. cornerRadius는 이 값의 1/2로 파생
    static let keyPointBadgeSize: CGFloat = 24

    /// KeyPointCell 뱃지와 본문 텍스트 사이 간격 (8)
    static let keyPointContentSpacing: CGFloat = 8

    /// KeyPointCell 카드 좌우 패딩 (12)
    static let keyPointCardHorizontalPadding: CGFloat = 12

    /// KeyPointCell 카드 상하 패딩 (8)
    static let keyPointCardVerticalPadding: CGFloat = 8
}

// MARK: - UnderlineTabButton Constants

public extension Constant {
    /// UnderlineTabButton 타이틀과 카운트 사이 간격 (4)
    static let underlineTabContentSpacing: CGFloat = 4

    /// UnderlineTabButton 선택 인디케이터 높이 (2)
    static let underlineTabIndicatorHeight: CGFloat = 2
}

// MARK: - UnderlineSegmentedControl Constants

public extension Constant {
    /// UnderlineSegmentedControl 표준 높이 (42)
    static let underlineSegmentedControlHeight: CGFloat = 42

    /// UnderlineSegmentedControl 상단 여백 (safeArea 기준, 16)
    static let underlineSegmentedControlTopMargin: CGFloat = 16
}

// MARK: - SkeletonLineView Constants

public extension Constant {
    /// SkeletonLineView 높이 (14) — cornerRadius는 이 값의 1/2로 파생
    static let skeletonLineHeight: CGFloat = 14

    /// SkeletonLineView 그라디언트 끝(투명) alpha
    static let skeletonLineTrailingAlpha: CGFloat = 0.05

    /// SkeletonLineView scaleX 애니메이션 시작값
    static let skeletonScaleFrom: CGFloat = 0.1

    /// SkeletonLineView scaleX 애니메이션 끝값
    static let skeletonScaleTo: CGFloat = 1.0

    /// SkeletonLineView scaleX 애니메이션 편도 주기 (초)
    static let skeletonAnimationDuration: CFTimeInterval = 1.0
}

// MARK: - BackgroundView Constants

public extension Constant {
    /// 첫 번째 타원 초기 높이 (195)
    static let ellipseFirstHeight: CGFloat = 195
    /// 두 번째 타원 초기 높이 (116)
    static let ellipseSecondHeight: CGFloat = 116
    /// 첫 번째 타원 초기 Blur (100)
    static let ellipseFirstBlur: CGFloat = 100
    /// 두 번째 타원 초기 Blur (40)
    static let ellipseSecondBlur: CGFloat = 40

    /// 첫 번째 타원 Blur 진폭 배율 (250)
    static let ellipseFirstBlurAmplitudeMultiplier: CGFloat = 250
    /// 두 번째 타원 Blur 진폭 배율 (100)
    static let ellipseSecondBlurAmplitudeMultiplier: CGFloat = 100
    /// 첫 번째 타원 높이 진폭 배율 (643)
    static let ellipseFirstHeightAmplitudeMultiplier: CGFloat = 643
    /// 두 번째 타원 높이 진폭 배율 (204)
    static let ellipseSecondHeightAmplitudeMultiplier: CGFloat = 204

    /// 첫 번째 타원 Leading Offset (-16)
    static let ellipseFirstLeadingOffset: CGFloat = -16
    /// 첫 번째 타원 Trailing Offset (16)
    static let ellipseFirstTrailingOffset: CGFloat = 16
    /// 첫 번째 타원 Bottom Offset (69)
    static let ellipseFirstBottomOffset: CGFloat = 69
    /// 두 번째 타원 Bottom Offset (100)
    static let ellipseSecondBottomOffset: CGFloat = 100
}

// MARK: - VoiceNote Layout Constants

public extension Constant {
    /// BottomFadeView 높이 (192)
    static let voiceNoteBottomFadeHeight: CGFloat = 192

    /// MatchAccessoryBar 좌우 수평 마진 (20)
    static let matchAccessoryBarHorizontalMargin: CGFloat = 20

    /// MatchAccessoryBar 키보드 상단 간격 (8)
    static let matchAccessoryBarKeyboardSpacing: CGFloat = 8
}
