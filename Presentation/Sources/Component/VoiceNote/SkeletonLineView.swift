import UIKit

final class SkeletonLineView: UIView {
    private static let animationKey = "skeleton.scaleX"

    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        layer.addSublayer(gradientLayer)
        gradientLayer.startPoint = .init(x: 0, y: 0.5)
        gradientLayer.endPoint = .init(x: 1, y: 0.5)
        gradientLayer.cornerRadius = Constant.skeletonLineHeight / 2
        gradientLayer.colors = [
            UIColor.gray400.cgColor,
            UIColor.gray900.withAlphaComponent(Constant.skeletonLineTrailingAlpha).cgColor
        ]
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Constant.skeletonLineHeight)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.anchorPoint = .init(x: 0, y: 0.5)
        gradientLayer.bounds = CGRect(origin: .zero, size: bounds.size)
        gradientLayer.position = CGPoint(x: 0, y: bounds.midY)
    }

    func startAnimating(beginOffset: CFTimeInterval = 0) {
        let animation = CABasicAnimation(keyPath: "transform.scale.x")
        animation.fromValue = Constant.skeletonScaleFrom
        animation.toValue = Constant.skeletonScaleTo
        animation.duration = Constant.skeletonAnimationDuration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.beginTime = CACurrentMediaTime() + beginOffset
        animation.fillMode = .both
        gradientLayer.add(animation, forKey: Self.animationKey)
    }

    func stopAnimating() {
        gradientLayer.removeAnimation(forKey: Self.animationKey)
    }
}

#Preview {
    let container = UIView()
    container.backgroundColor = UIColor.gray100

    let widths: [CGFloat] = [204, 173, 225]
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 6
    stack.alignment = .leading
    stack.translatesAutoresizingMaskIntoConstraints = false

    for (index, w) in widths.enumerated() {
        let line = SkeletonLineView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.widthAnchor.constraint(equalToConstant: w).isActive = true
        line.startAnimating(beginOffset: Double(index) * 0.2)
        stack.addArrangedSubview(line)
    }

    container.addSubview(stack)
    NSLayoutConstraint.activate([
        stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
        stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
    ])
    return container
}
