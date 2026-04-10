import UIKit

final class UnderlineTabButton: UIControl {
    private(set) var isSelected: Bool = false
    private let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()

    private let indicator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.point700
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Init

    init(title: String, isSelected: Bool = false) {
        super.init(frame: .zero)
        label.text = title
        setupUI()
        setSelected(isSelected, animated: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(label)
        addSubview(indicator)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),

            indicator.leadingAnchor.constraint(equalTo: leadingAnchor),
            indicator.trailingAnchor.constraint(equalTo: trailingAnchor),
            indicator.bottomAnchor.constraint(equalTo: bottomAnchor),
            indicator.heightAnchor.constraint(equalToConstant: 2)
        ])
    }

    func setSelected(_ isSelected: Bool, animated: Bool = true) {
        self.isSelected = isSelected
        if isSelected {
            label.setTypography(style: .title3)
            label.textColor = .white
            indicator.isHidden = false
        } else {
            label.setTypography(style: .body2)
            label.textColor = UIColor.gray600
            indicator.isHidden = true
        }
    }
}
