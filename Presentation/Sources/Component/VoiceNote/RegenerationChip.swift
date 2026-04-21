import UIKit

final class RegenerationChip: UIView {
    enum State {
        case idle
        case loading
        case outdated
    }

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = UIColor.gray775
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let label: TypographyLabel = {
        let label = TypographyLabel(typography: .label)
        label.textColor = UIColor.gray775
        return label
    }()

    private let indicatorDot: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.warning
        view.layer.cornerRadius = Constant.chipIndicatorSize / 2
        return view
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Constant.chipContentSpacing
        return stack
    }()

    init(state: State = .idle) {
        super.init(frame: .zero)
        setupUI()
        apply(state: state)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    func apply(state: State) {
        iconView.isHidden = !state.showsIcon
        indicatorDot.isHidden = !state.showsIndicator
        label.text = state.text
        isUserInteractionEnabled = state.isInteractive
    }

    private func setupUI() {
        backgroundColor = UIColor.point150
        layer.borderColor = UIColor.point600.cgColor
        layer.borderWidth = Constant.borderWidth
        clipsToBounds = true

        iconView.image = UIImage(systemName: "arrow.clockwise")

        for subview in [stackView, iconView, label, indicatorDot] {
            subview.translatesAutoresizingMaskIntoConstraints = false
        }

        addSubview(stackView)
        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(indicatorDot)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Constant.chipVerticalPadding),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constant.chipHorizontalPadding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constant.chipHorizontalPadding),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constant.chipVerticalPadding),
            iconView.widthAnchor.constraint(equalToConstant: Constant.chipIconSize),
            iconView.heightAnchor.constraint(equalToConstant: Constant.chipIconSize),
            indicatorDot.widthAnchor.constraint(equalToConstant: Constant.chipIndicatorSize),
            indicatorDot.heightAnchor.constraint(equalToConstant: Constant.chipIndicatorSize),
            heightAnchor.constraint(greaterThanOrEqualToConstant: Constant.chipMinimumHeight)
        ])
    }
}

private extension RegenerationChip.State {
    var text: String {
        switch self {
        case .idle, .outdated: return "재생성"
        case .loading: return "재생성 중..."
        }
    }

    var showsIcon: Bool {
        switch self {
        case .idle, .outdated: return true
        case .loading: return false
        }
    }

    var showsIndicator: Bool {
        switch self {
        case .outdated: return true
        case .idle, .loading: return false
        }
    }

    var isInteractive: Bool {
        switch self {
        case .idle, .outdated: return true
        case .loading: return false
        }
    }
}

#Preview("idle") {
    RegenerationChip(state: .idle)
}

#Preview("loading") {
    RegenerationChip(state: .loading)
}

#Preview("outdated") {
    RegenerationChip(state: .outdated)
}
