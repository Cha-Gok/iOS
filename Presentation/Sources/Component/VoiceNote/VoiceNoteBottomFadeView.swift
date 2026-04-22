import UIKit

final class VoiceNoteBottomFadeView: UIView {
    private let gradientLayer = CAGradientLayer()

    init() {
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = false
        backgroundColor = .clear

        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.colors = [
            UIColor.gray0.withAlphaComponent(0).cgColor,
            UIColor.gray0.cgColor
        ]
        layer.addSublayer(gradientLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

#Preview {
    let container = UIView()
    container.backgroundColor = .gray0

    let content = UILabel()
    content.text = Array(repeating: "컨텐츠 컨텐츠 컨텐츠 컨텐츠 컨텐츠", count: 8).joined(separator: "\n")
    content.numberOfLines = 0
    content.textColor = .gray950
    content.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(content)

    let fade = VoiceNoteBottomFadeView()
    container.addSubview(fade)

    NSLayoutConstraint.activate([
        content.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
        content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
        content.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

        fade.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        fade.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        fade.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        fade.heightAnchor.constraint(equalToConstant: 80)
    ])

    return container
}
