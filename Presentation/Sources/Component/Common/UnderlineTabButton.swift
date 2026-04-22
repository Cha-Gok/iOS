import UIKit

final class UnderlineTabButton: UIControl {
    private let titleLabel = TypographyLabel(typography: .body1, alignment: .center)
    private let countLabel: TypographyLabel = {
        let label = TypographyLabel(typography: .title3, alignment: .center)
        label.textColor = UIColor.point700
        label.isHidden = true
        return label
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, countLabel])
        stack.axis = .horizontal
        stack.spacing = Constant.underlineTabContentSpacing
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        return stack
    }()

    private let indicator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.point700
        view.isUserInteractionEnabled = false
        return view
    }()

    // MARK: - Init

    init(title: String, isSelected: Bool = false) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupUI()
        setSelected(isSelected, animated: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(contentStack)
        addSubview(indicator)

        for subview in [contentStack, indicator] {
            subview.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            indicator.leadingAnchor.constraint(equalTo: leadingAnchor),
            indicator.trailingAnchor.constraint(equalTo: trailingAnchor),
            indicator.bottomAnchor.constraint(equalTo: bottomAnchor),
            indicator.heightAnchor.constraint(equalToConstant: Constant.underlineTabIndicatorHeight)
        ])
    }

    func setSelected(_ isSelected: Bool, animated: Bool = true) {
        self.isSelected = isSelected
        indicator.isHidden = !isSelected
        titleLabel.typography = isSelected ? .title3 : .body1
        titleLabel.textColor = isSelected ? UIColor.gray950 : UIColor.gray600
    }

    /// 탭 제목 우측에 표시할 카운트. `nil`이면 숨깁니다.
    func setCount(_ count: Int?) {
        if let count {
            countLabel.text = "\(count)"
            countLabel.isHidden = false
        } else {
            countLabel.text = nil
            countLabel.isHidden = true
        }
    }
}
