import UIKit

struct KeywordsContentConfiguration: UIContentConfiguration {
    var keywords: [String] = []

    func makeContentView() -> UIView & UIContentView {
        KeywordsContentView(configuration: self)
    }

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

    private var chipViews: [KeywordChipLabel] = []
    private var contentHeight: CGFloat = 0

    init(configuration: UIContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        apply(configuration: configuration)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentHeight = layoutChips(for: bounds.width, shouldApplyFrames: true)
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: contentHeight)
    }

    private func apply(configuration: UIContentConfiguration) {
        guard let config = configuration as? KeywordsContentConfiguration else { return }

        chipViews.forEach { $0.removeFromSuperview() }
        chipViews = config.keywords.map(KeywordChipLabel.init(text:))
        chipViews.forEach(addSubview)

        contentHeight = 0
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

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
