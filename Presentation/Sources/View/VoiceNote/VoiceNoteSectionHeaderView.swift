import UIKit

final class VoiceNoteSectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "FileDetailSectionHeaderView"

    // MARK: - UI Components

    private let titleLabel: TypographyLabel = {
        let label = TypographyLabel(typography: .title2)
        label.textColor = .gray950
        return label
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        return stack
    }()

    private var onTrailingTap: (() -> Void)?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - Setup

    private func setupUI() {
        contentStack.addArrangedSubview(titleLabel)
        addSubview(contentStack)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    // MARK: - Configure

    func configure(title: String, trailingView: UIView? = nil, onTrailingTap: (() -> Void)? = nil) {
        titleLabel.text = title
        self.onTrailingTap = onTrailingTap
        setTrailingView(trailingView)
    }

    // MARK: - Private

    private func setTrailingView(_ view: UIView?) {
        contentStack.arrangedSubviews
            .filter { $0 !== titleLabel }
            .forEach { $0.removeFromSuperview() }

        guard let view else { return }
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        contentStack.addArrangedSubview(spacer)
        contentStack.addArrangedSubview(view)

        if onTrailingTap != nil {
            view.isUserInteractionEnabled = true
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(trailingTapped)))
        }
    }

    @objc
    private func trailingTapped() {
        onTrailingTap?()
    }
}

#Preview("trailingView 있음") {
    let header = VoiceNoteSectionHeaderView()
    let chip = RegenerationChip(state: .idle)
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
