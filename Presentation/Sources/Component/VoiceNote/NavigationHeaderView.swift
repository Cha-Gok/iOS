import UIKit

final class NavigationHeaderView: UIView {
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = 8
        return stack
    }()

    private let leftStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = 8
        return stack
    }()

    private let titleContainer = UIView()

    private let rightStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = 8
        return stack
    }()

    // MARK: - Public API

    func setLeftButtons(_ buttons: [UIButton]) {
        replaceArrangedSubviews(of: leftStack, with: buttons)
    }

    func setRightButtons(_ buttons: [UIButton]) {
        replaceArrangedSubviews(of: rightStack, with: buttons)
    }

    func setTitleView(_ view: UIView?) {
        replaceSubview(of: titleContainer, with: view)
    }

    private func replaceArrangedSubviews(of stack: UIStackView, with views: [UIView]) {
        for subview in stack.arrangedSubviews {
            stack.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        for view in views {
            stack.addArrangedSubview(view)
        }
    }

    private func replaceSubview(of container: UIView, with view: UIView?) {
        container.subviews.forEach { $0.removeFromSuperview() }
        guard let view else { return }
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = UIColor.gray0

        leftStack.setContentHuggingPriority(.required, for: .horizontal)
        leftStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        rightStack.setContentHuggingPriority(.required, for: .horizontal)
        rightStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleContainer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleContainer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        contentStack.addArrangedSubview(leftStack)
        contentStack.addArrangedSubview(titleContainer)
        contentStack.addArrangedSubview(rightStack)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 80),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24)
        ])
    }
}
