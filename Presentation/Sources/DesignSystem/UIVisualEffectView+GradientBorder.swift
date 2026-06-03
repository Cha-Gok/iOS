import UIKit

private final class GradientBorderOverlayView: UIView {
    private let gradientLayer = CAGradientLayer()
    private let borderMaskLayer = CAShapeLayer()

    private var borderWidth: CGFloat = 1
    private var borderCornerRadius: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = false
        backgroundColor = .clear

        borderMaskLayer.fillColor = UIColor.clear.cgColor
        borderMaskLayer.strokeColor = UIColor.black.cgColor
        gradientLayer.mask = borderMaskLayer

        layer.addSublayer(gradientLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(
        colors: [UIColor],
        width: CGFloat,
        cornerRadius: CGFloat,
        startPoint: CGPoint,
        endPoint: CGPoint
    ) {
        borderWidth = width
        borderCornerRadius = cornerRadius
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        borderMaskLayer.lineWidth = width

        setNeedsLayout()
    }

    func updateCornerRadius(_ cornerRadius: CGFloat) {
        borderCornerRadius = cornerRadius
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer.frame = bounds

        let inset = borderWidth / 2
        let borderRect = bounds.insetBy(dx: inset, dy: inset)
        let path = UIBezierPath(
            roundedRect: borderRect,
            cornerRadius: max(borderCornerRadius - inset, 0)
        )

        borderMaskLayer.path = path.cgPath
    }
}

private extension UIVisualEffectView {
    var gradientBorderOverlayView: GradientBorderOverlayView? {
        contentView.subviews.first { $0 is GradientBorderOverlayView } as? GradientBorderOverlayView
    }
}

extension UIVisualEffectView {
    func setGradientBorder(
        colors: [UIColor],
        width: CGFloat = 1,
        cornerRadius: CGFloat,
        startPoint: CGPoint = CGPoint(x: 0, y: 0.5),
        endPoint: CGPoint = CGPoint(x: 1, y: 0.5)
    ) {
        guard !colors.isEmpty else {
            removeGradientBorder()
            return
        }

        let overlayView: GradientBorderOverlayView

        if let existingOverlay = gradientBorderOverlayView {
            overlayView = existingOverlay
        } else {
            overlayView = GradientBorderOverlayView()
            overlayView.translatesAutoresizingMaskIntoConstraints = false

            contentView.addSubview(overlayView)
            NSLayoutConstraint.activate([
                overlayView.topAnchor.constraint(equalTo: contentView.topAnchor),
                overlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                overlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                overlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }

        overlayView.configure(
            colors: colors,
            width: width,
            cornerRadius: cornerRadius,
            startPoint: startPoint,
            endPoint: endPoint
        )

        contentView.bringSubviewToFront(overlayView)
    }

    func updateGradientBorderCornerRadius(_ cornerRadius: CGFloat) {
        gradientBorderOverlayView?.updateCornerRadius(cornerRadius)
    }

    func removeGradientBorder() {
        gradientBorderOverlayView?.removeFromSuperview()
    }
}
