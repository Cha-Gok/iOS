import UIKit

final class UnderlineSegmentedControl: UIControl {
    private(set) var selectedSegmentIndex: Int = 0

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var buttons: [UnderlineTabButton] = []

    // MARK: - Init

    init(items: [String]) {
        super.init(frame: .zero)
        setupButtons(items: items)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Constant.underlineSegmentedControlHeight)
    }

    // MARK: - Setup

    private func setupButtons(items: [String]) {
        buttons = items.enumerated().map { index, title in
            let button = UnderlineTabButton(title: title, isSelected: index == selectedSegmentIndex)
            button.addAction(UIAction { [weak self] _ in
                self?.selectSegment(index: index)
                self?.sendActions(for: .valueChanged)
            }, for: .touchUpInside)
            return button
        }
    }

    private func setupUI() {
        addSubview(stackView)
        buttons.forEach { stackView.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Actions

    func selectSegment(index: Int, animated: Bool = true) {
        selectedSegmentIndex = index
        for (idx, button) in buttons.enumerated() {
            button.setSelected(idx == index, animated: animated)
        }
    }

    /// 지정한 인덱스의 탭에 카운트 배지를 표시합니다. `nil`이면 카운트를 숨깁니다.
    func setCount(_ count: Int?, at index: Int) {
        guard buttons.indices.contains(index) else { return }
        buttons[index].setCount(count)
    }
}
