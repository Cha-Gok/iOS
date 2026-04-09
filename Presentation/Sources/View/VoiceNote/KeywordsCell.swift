import UIKit

struct KeywordsContentConfiguration: UIContentConfiguration {
    var keywords: [String] = []

    /// 키워드 전용 content view를 생성합니다.
    func makeContentView() -> UIView & UIContentView {
        KeywordsContentView(configuration: self)
    }

    /// 상태 변화가 있어도 별도 스타일 변경 없이 현재 값을 유지합니다.
    func updated(for state: UIConfigurationState) -> KeywordsContentConfiguration {
        self
    }
}

final class KeywordsContentView: UIView, UIContentView {
    var configuration: UIContentConfiguration {
        didSet { apply(configuration: configuration) }
    }

    private let interItemSpacing: CGFloat = Constant.keywordChipInterItemSpacing
    private let lineSpacing: CGFloat = Constant.keywordChipLineSpacing

    private var chipViews: [KeywordChipView] = []
    private var contentHeight: CGFloat = 0

    /// 초기 configuration으로 칩 목록을 구성합니다.
    init(configuration: UIContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        apply(configuration: configuration)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    /// 현재 너비 기준으로 칩 프레임을 다시 계산합니다.
    override func layoutSubviews() {
        super.layoutSubviews()
        contentHeight = layoutChips(for: bounds.width, shouldApplyFrames: true)
        invalidateIntrinsicContentSize()
    }

    /// 셀 높이 계산에 사용할 콘텐츠 높이를 반환합니다.
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: contentHeight)
    }

    /// configuration의 키워드 목록으로 칩 뷰를 갱신합니다.
    private func apply(configuration: UIContentConfiguration) {
        guard let config = configuration as? KeywordsContentConfiguration else { return }

        chipViews.forEach { $0.removeFromSuperview() }
        chipViews = config.keywords.map(KeywordChipView.init(text:))
        chipViews.forEach(addSubview)

        contentHeight = 0
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    /// 칩을 한 줄씩 배치하고, 필요하면 실제 프레임까지 적용합니다.
    private func layoutChips(for availableWidth: CGFloat, shouldApplyFrames: Bool) -> CGFloat {
        guard availableWidth > 0, chipViews.isEmpty == false else { return 0 }

        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        var rowHeight: CGFloat = 0

        for chipView in chipViews {
            let chipSize = chipView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

            if xOffset > 0, xOffset + chipSize.width > availableWidth {
                xOffset = 0
                yOffset += rowHeight + lineSpacing
                rowHeight = 0
            }

            if shouldApplyFrames {
                chipView.frame = CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: chipSize)
            }

            xOffset += chipSize.width + interItemSpacing
            rowHeight = max(rowHeight, chipSize.height)
        }

        return yOffset + rowHeight
    }
}

final class KeywordsCell: UICollectionViewCell {
    /// self-sizing 셀이 키워드 줄 수에 맞는 높이를 갖도록 보정합니다.
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes)
        -> UICollectionViewLayoutAttributes
    {
        setNeedsLayout()
        layoutIfNeeded()

        let size = contentView.systemLayoutSizeFitting(
            CGSize(width: layoutAttributes.frame.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        layoutAttributes.frame.size.height = size.height
        return layoutAttributes
    }
}
