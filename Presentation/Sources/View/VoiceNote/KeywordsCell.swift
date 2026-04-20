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

    private var chipLabels: [KeywordChipLabel] = []
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
        contentHeight = layoutChips(for: bounds.width)
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: contentHeight)
    }

    private func apply(configuration: UIContentConfiguration) {
        guard let config = configuration as? KeywordsContentConfiguration else { return }

        chipLabels.forEach { $0.removeFromSuperview() }
        chipLabels = config.keywords.map(KeywordChipLabel.init(text:))
        chipLabels.forEach(addSubview)

        contentHeight = 0
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    private func layoutChips(for availableWidth: CGFloat) -> CGFloat {
        guard availableWidth > 0, chipLabels.isEmpty == false else { return 0 }

        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        var rowHeight: CGFloat = 0

        for chipLabel in chipLabels {
            let chipSize = chipLabel.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

            if xOffset > 0, xOffset + chipSize.width > availableWidth {
                xOffset = 0
                yOffset += rowHeight + lineSpacing
                rowHeight = 0
            }

            chipLabel.frame = CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: chipSize)

            xOffset += chipSize.width + interItemSpacing
            rowHeight = max(rowHeight, chipSize.height)
        }

        return yOffset + rowHeight
    }
}
