import UIKit

final class PlaybackProgressView: UIView {
    var onSeekBegan: (() -> Void)?
    var onValueChanging: ((TimeInterval) -> Void)?
    var onSeekEnded: ((TimeInterval) -> Void)?

    private(set) var isInteracting = false

    private var duration: TimeInterval = 0
    private var currentTime: TimeInterval = 0

    private let trackFill = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func setDuration(_ duration: TimeInterval) {
        guard self.duration != duration else { return }
        self.duration = duration
        setNeedsLayout()
    }

    func setCurrentTime(_ time: TimeInterval) {
        guard !isInteracting else { return }
        currentTime = max(0, min(duration, time))
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let ratio = duration > 0 ? CGFloat(currentTime / duration) : 0
        let clamped = max(0, min(1, ratio))
        trackFill.frame = CGRect(x: 0, y: 0, width: bounds.width * clamped, height: bounds.height)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.insetBy(dx: 0, dy: -11).contains(point)
    }

    private func setup() {
        backgroundColor = .gray200

        trackFill.backgroundColor = .point700
        addSubview(trackFill)

        let press = UILongPressGestureRecognizer(target: self, action: #selector(handlePress(_:)))
        press.minimumPressDuration = 0
        addGestureRecognizer(press)
    }

    private func time(atX x: CGFloat) -> TimeInterval {
        guard bounds.width > 0, duration > 0 else { return 0 }
        let ratio = max(0, min(1, x / bounds.width))
        return Double(ratio) * duration
    }

    @objc
    private func handlePress(_ recognizer: UILongPressGestureRecognizer) {
        guard duration > 0 else { return }
        let t = time(atX: recognizer.location(in: self).x)

        switch recognizer.state {
        case .began:
            isInteracting = true
            currentTime = t
            setNeedsLayout()
            onSeekBegan?()
            onValueChanging?(t)
        case .changed:
            currentTime = t
            setNeedsLayout()
            onValueChanging?(t)
        case .ended, .cancelled, .failed:
            currentTime = t
            setNeedsLayout()
            isInteracting = false
            onSeekEnded?(t)
        default:
            break
        }
    }
}

#Preview("시작") {
    let container = UIView()
    container.backgroundColor = .gray0

    let view = PlaybackProgressView()
    view.setDuration(100)
    view.setCurrentTime(0)
    view.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(view)

    NSLayoutConstraint.activate([
        view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
        view.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
        view.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        view.heightAnchor.constraint(equalToConstant: 8)
    ])

    return container
}

#Preview("중간") {
    let container = UIView()
    container.backgroundColor = .gray0

    let view = PlaybackProgressView()
    view.setDuration(100)
    view.setCurrentTime(40)
    view.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(view)

    NSLayoutConstraint.activate([
        view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
        view.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
        view.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        view.heightAnchor.constraint(equalToConstant: 8)
    ])

    return container
}

#Preview("끝") {
    let container = UIView()
    container.backgroundColor = .gray0

    let view = PlaybackProgressView()
    view.setDuration(100)
    view.setCurrentTime(100)
    view.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(view)

    NSLayoutConstraint.activate([
        view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
        view.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
        view.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        view.heightAnchor.constraint(equalToConstant: 8)
    ])

    return container
}
