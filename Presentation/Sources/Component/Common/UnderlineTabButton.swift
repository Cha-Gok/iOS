import UIKit

final class UnderlineTabButton: UIControl {
    private let title: String
    private var count: Int?

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
        self.title = title
        super.init(frame: .zero)
        updateLabelText()
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

    /// 탭 제목 우측에 표시할 카운트. `nil`이면 원본 제목만 노출합니다.
    func setCount(_ count: Int?) {
        self.count = count
        updateLabelText()
    }

    private func updateLabelText() {
        if let count {
            label.text = "\(title) \(count)"
        } else {
            label.text = title
        }
    }
}
