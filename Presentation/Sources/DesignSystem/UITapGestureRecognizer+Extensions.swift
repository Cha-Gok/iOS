import UIKit

// MARK: - BlockTapGestureRecognizer

public final class BlockTapGestureRecognizer: UITapGestureRecognizer {
    private var action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
        super.init(target: nil, action: nil)
        addTarget(self, action: #selector(handleTap))
    }

    @objc
    private func handleTap() {
        action()
    }
}

// MARK: - UIView+TapGesture

public extension UIView {
    func addTapGesture(action: @escaping () -> Void) {
        let tap = BlockTapGestureRecognizer(action: action)
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }
}
