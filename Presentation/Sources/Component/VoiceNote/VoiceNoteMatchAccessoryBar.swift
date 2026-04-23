import UIKit

public final class VoiceNoteMatchAccessoryBar: UIView {
    public var onPrev: (() -> Void)?
    public var onNext: (() -> Void)?

    private let countLabel: TypographyLabel = {
        let label = TypographyLabel(typography: .title3)
        label.text = "1 / 2"
        label.textColor = .gray950
        label.textAlignment = .center
        return label
    }()

    private let prevButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(.chevronUp, for: .normal)
        button.tintColor = .gray950
        return button
    }()

    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(.chevronDown, for: .normal)
        button.tintColor = .gray950
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [prevButton, countLabel, nextButton])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .top
        return stack
    }()

    public init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 48))
        autoresizingMask = [.flexibleWidth]
        backgroundColor = .gray200
        setupUI()
        setupActions()
        configure(countText: "0 / 0", hasMatches: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    public func configure(countText: String, hasMatches: Bool) {
        countLabel.text = countText
        prevButton.isEnabled = hasMatches
        nextButton.isEnabled = hasMatches
        prevButton.tintColor = hasMatches ? .gray950 : .gray600
        nextButton.tintColor = hasMatches ? .gray950 : .gray600
    }

    private func setupUI() {
        for button in [prevButton, nextButton] {
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 24),
                button.heightAnchor.constraint(equalToConstant: 24)
            ])
        }

        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    private func setupActions() {
        prevButton.addAction(UIAction { [weak self] _ in
            self?.onPrev?()
        }, for: .touchUpInside)

        nextButton.addAction(UIAction { [weak self] _ in
            self?.onNext?()
        }, for: .touchUpInside)
    }
}
