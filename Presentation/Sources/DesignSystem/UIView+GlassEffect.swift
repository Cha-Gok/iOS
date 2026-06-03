import UIKit

extension UIView {
    func applyGlassEffect(
        cornerRadius: CGFloat = 20,
        isInteractive: Bool = false,
        tintColor: UIColor
    ) {
        // 중복 추가 방지
        if subviews.contains(where: { $0 is UIVisualEffectView }) { return }
        let glassEffect = UIGlassEffect(style: .clear)
        UIView.animate {
            glassEffect.isInteractive = isInteractive
            glassEffect.tintColor = tintColor
        }
        let visualEffectView = UIVisualEffectView(effect: glassEffect)
        visualEffectView.cornerConfiguration = .corners(radius: .fixed(cornerRadius))
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(visualEffectView, at: 0)
        NSLayoutConstraint.activate([
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
