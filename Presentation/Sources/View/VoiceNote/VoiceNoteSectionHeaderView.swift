import UIKit

final class VoiceNoteSectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "FileDetailSectionHeaderView"

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var trailingView: UIView?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - Configure

    func configure(title: String, trailingView: UIView? = nil) {
        titleLabel.setTypography(text: title, style: .title2)
        setTrailingView(trailingView)
    }

    // MARK: - Private

    private func setTrailingView(_ view: UIView?) {
        trailingView?.removeFromSuperview()
        trailingView = view

        guard let view else { return }
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            view.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

#Preview("trailingView 있음") {
    let header = VoiceNoteSectionHeaderView()
    let chip = ChipView(icon: UIImage(systemName: "arrow.clockwise"), text: "재생성")
    header.configure(title: "핵심 포인트", trailingView: chip)
    header.backgroundColor = .black
    return header
}

#Preview("trailingView 없음") {
    let header = VoiceNoteSectionHeaderView()
    header.configure(title: "키워드")
    header.backgroundColor = .black
    return header
}
