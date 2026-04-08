import UIKit

final class MainEmptyListCell: UICollectionViewCell {
    static let reuseIdentifier: String = "MainEmptyListCell"

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.setTypography(text: "아직 녹음된 기록이 없습니다", style: .subtitle2)
        l.textColor = UIColor.gray600
        l.textAlignment = .center
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentView.addSubview(messageLabel)
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 96),
            messageLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
}
