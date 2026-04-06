import UIKit

public final class RecordingBackgroundView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func updateValue(_ amplitude: Float) {
        backgroundColor = UIColor(hue: CGFloat(amplitude) * 0.67, saturation: 0.8, brightness: 0.8, alpha: 1)
    }
}
