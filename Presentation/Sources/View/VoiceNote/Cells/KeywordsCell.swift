import UIKit

struct KeywordsContentConfiguration: UIContentConfiguration {
    var keywords: [String] = []
    var keywordHighlightRanges: [[NSRange]] = []
    var focusedKeywordIndex: Int?
    var focusedRange: NSRange?

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
        chipLabels = config.keywords.enumerated().map { index, keyword in
            let chip = KeywordChipLabel(text: keyword)
            let ranges = config.keywordHighlightRanges.indices.contains(index)
                ? config.keywordHighlightRanges[index] : []
            let focusedRange = index == config.focusedKeywordIndex ? config.focusedRange : nil
            chip.applyHighlight(
                ranges: ranges,
                highlightBackgroundColor: UIColor.point700,
                focusedRange: focusedRange,
                focusedHighlightBackgroundColor: .warning2
            )
            return chip
        }
        chipLabels.forEach(addSubview)
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
                yOffset += rowHeight + Constant.keywordChipLineSpacing
                rowHeight = 0
            }

            chipLabel.frame = CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: chipSize)

            xOffset += chipSize.width + Constant.keywordChipInterItemSpacing
            rowHeight = max(rowHeight, chipSize.height)
        }

        return yOffset + rowHeight
    }
}

#Preview {
    let viewController = UIViewController()
    viewController.view.backgroundColor = .systemBackground

    let contentView = KeywordsContentConfiguration(
        keywords: ["Swift", "UIKit", "프리뷰", "키워드", "자동 사이징", "SwiftUI", "Xcode"]
    ).makeContentView()
    contentView.translatesAutoresizingMaskIntoConstraints = false
    viewController.view.addSubview(contentView)

    NSLayoutConstraint.activate([
        contentView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 20),
        contentView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -20),
        contentView.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
    ])

    return viewController
}
